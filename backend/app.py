import os
import joblib
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
from sqlalchemy.exc import SQLAlchemyError
from decimal import Decimal

from db import AnalysisRecord, get_session, init_db

app = Flask(__name__)
CORS(app)

MODEL_PATH = os.path.join('models', 'pregnancy_pipeline.joblib')

init_db()


def log_status(stage: str, message: str, icon: str = "🔹") -> None:
    print(f"{icon} [{stage}] {message}")


def sanitize_payload(data):
    if data is None:
        return {}
    if isinstance(data, dict):
        cleaned = {}
        for key, value in data.items():
            if key == "imageBytes":
                continue
            if key == "imageBase64":
                if isinstance(value, str) and len(value) > 0:
                    max_base64_size = 800 * 1024
                    if len(value) <= max_base64_size:
                        cleaned[key] = value
                    else:
                        print(f"⚠️ ImageBase64 muito grande ({len(value)} chars), removendo")
                continue
            cleaned[key] = sanitize_payload(value)
        return cleaned
    if isinstance(data, list):
        return [sanitize_payload(item) for item in data]
    if isinstance(data, (str, int, float, bool)) or data is None:
        return data
    return str(data)


def _to_serializable(value):
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, dict):
        return {k: _to_serializable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_to_serializable(v) for v in value]
    return value


def serialize_analysis(record: AnalysisRecord) -> dict:
    return {
        'id': record.id,
        'cow_id': record.cow_id,
        'prediction': int(record.prediction) if record.prediction is not None else None,
        'prediction_label': record.prediction_label,
        'probability': float(record.probability) if record.probability is not None else None,
        'payload': _to_serializable(record.payload) if record.payload else {},
        'status': record.status,
        'notes': record.notes,
        'created_at': record.created_at.isoformat() if record.created_at else None,
        'updated_at': record.updated_at.isoformat() if record.updated_at else None,
    }


def persist_analysis(input_payload: dict, result_payload: dict, status="completed", notes=None):
    session = get_session()
    cow_identifier = (
        input_payload.get('cowId')
        or input_payload.get('cow_id')
        or input_payload.get('cow')
        or "SEM_ID"
    )

    try:
        log_status("DB", "Conectando para salvar análise...", "🔄")
        sanitized = sanitize_payload(input_payload)
        if isinstance(sanitized, dict):
            image_path = sanitized.get('imagePath')
            image_base64 = sanitized.get('imageBase64')
            if image_path:
                log_status("DB", f"ImagePath preservado: {image_path}", "📸")
            if image_base64:
                base64_size = len(image_base64) if isinstance(image_base64, str) else 0
                log_status("DB", f"ImageBase64 preservado: {base64_size} caracteres", "📸")
        record = AnalysisRecord(
            cow_id=str(cow_identifier),
            prediction=int(result_payload.get('prediction', 0)),
            prediction_label=result_payload.get('prenhez', 'N/A'),
            probability=float(result_payload.get('confidence', 0.0)),
            payload=sanitized,
            status=status,
            notes=notes,
        )
        session.add(record)
        session.commit()
        session.refresh(record)
        log_status("DB", f"Análise #{record.id} salva com sucesso", "✅")
        if record.payload and isinstance(record.payload, dict):
            saved_path = record.payload.get('imagePath')
            saved_base64 = record.payload.get('imageBase64')
            if saved_path:
                log_status("DB", f"ImagePath confirmado no banco: {saved_path}", "✅")
            if saved_base64:
                base64_size = len(saved_base64) if isinstance(saved_base64, str) else 0
                log_status("DB", f"ImageBase64 confirmado no banco: {base64_size} caracteres", "✅")
        return record
    except SQLAlchemyError as exc:
        session.rollback()
        log_status("DB", f"Erro ao salvar análise: {exc}", "❌")
        raise
    finally:
        session.close()


def carregar_modelo():
    try:
        model_bundle = joblib.load(MODEL_PATH)
        pipeline = model_bundle["pipeline"]
        features = model_bundle["features"]
        metadata = model_bundle.get("metadata", {})
        print("✅ Modelo carregado:")
        print(f"   - Features: {features}")
        print(f"   - Tipo: {metadata.get('model_type', 'N/A')}")
        print(f"   - Número de features: {len(features)}")
        return pipeline, features, metadata
    except Exception as e:
        print(f"❌ Erro ao carregar modelo: {str(e)}")
        return None, [], {}


pipeline, model_features, model_metadata = carregar_modelo()
modelo_carregado = pipeline is not None


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'online',
        'model_loaded': modelo_carregado,
        'features_esperadas': model_features,
        'model_metadata': model_metadata
    })


@app.route('/predict', methods=['GET', 'POST', 'DELETE'])
def predict():
    if request.method == 'GET':
        return list_analyses()
    if request.method == 'DELETE':
        return delete_all_analyses()
    if not modelo_carregado:
        return jsonify({'error': 'Modelo não carregado'}), 500

    try:
        log_status("PREDICT", "Recebendo payload do cliente", "🚀")
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Dados JSON necessários'}), 400

        log_status("PREDICT", f"Payload recebido: {data}", "📥")

        missing_features = [f for f in model_features if f not in data]
        if missing_features:
            return jsonify({
                'error': 'Features faltando',
                'missing': missing_features,
                'required': model_features
            }), 400

        log_status("PREDICT", "Validando features e preparando dataframe", "🧮")
        input_data = {feature: [float(data[feature])] for feature in model_features}
        df_input = pd.DataFrame(input_data)

        log_status("PREDICT", "Rodando pipeline do modelo", "⚙️")
        prediction = int(pipeline.predict(df_input)[0])

        try:
            proba = pipeline.predict_proba(df_input)[0][1]
        except Exception as e:
            print(f"⚠️ Não foi possível calcular confiabilidade: {e}")
            proba = 0.5

        resultado = "SIM" if prediction == 1 else "NÃO"

        response = {
            'prenhez': resultado,
            'prediction': prediction,
            'confidence': float(proba),
            'confidence_percent': round(float(proba) * 100, 2),
            'status': 'success'
        }

        log_status(
            "PREDICT",
            f"Resultado: {resultado} | Confiança: {response['confidence_percent']}%",
            "📊",
        )

        try:
            record = persist_analysis(data, response)
            response['analysis_id'] = record.id
            response['analysis'] = serialize_analysis(record)
        except Exception as exc:
            log_status("PREDICT", f"Não foi possível salvar no banco: {exc}", "❌")
            return jsonify({'error': 'Falha ao salvar análise no banco'}), 500

        return jsonify(response)

    except Exception as e:
        log_status("PREDICT", f"Erro na predição: {e}", "❌")
        return jsonify({'error': str(e)}), 500


@app.route('/features', methods=['GET'])
def get_features():
    return jsonify({
        'features': model_features,
        'model_metadata': model_metadata
    })


@app.route('/analises', methods=['GET'])
def list_analyses():
    session = get_session()
    cow_id = request.args.get('cow_id')
    status = request.args.get('status')
    limit = min(request.args.get('limit', type=int) or 500, 500)
    offset = request.args.get('offset', type=int) or 0
    
    try:
        query = session.query(AnalysisRecord)
        if cow_id:
            query = query.filter(AnalysisRecord.cow_id == cow_id)
        if status:
            query = query.filter(AnalysisRecord.status == status)
        
        total_count = query.count()
        
        if total_count == 0:
            return jsonify({
                'data': [],
                'total': 0,
                'limit': limit,
                'offset': 0,
                'has_more': False
            })
        
        records = query.order_by(AnalysisRecord.id.desc()).limit(limit).offset(offset).all()
        
        records_sorted = sorted(records, key=lambda r: r.created_at if r.created_at else r.id, reverse=True)
        
        log_status("CRUD", f"{len(records_sorted)} análises retornadas (total: {total_count}, offset: {offset})", "📄")
        return jsonify({
            'data': [serialize_analysis(record) for record in records_sorted],
            'total': total_count,
            'limit': limit,
            'offset': offset,
            'has_more': (offset + len(records_sorted)) < total_count
        })
    except SQLAlchemyError as exc:
        session.rollback()
        log_status("CRUD", f"Erro ao listar análises: {exc}", "❌")
        return jsonify({'error': f'Erro ao buscar análises: {str(exc)}'}), 500
    except Exception as exc:
        log_status("CRUD", f"Erro inesperado ao listar análises: {exc}", "❌")
        return jsonify({'error': f'Erro inesperado: {str(exc)}'}), 500
    finally:
        session.close()


@app.route('/analises', methods=['POST'])
def create_analysis():
    payload = request.get_json()
    if not payload:
        return jsonify({'error': 'Dados JSON necessários'}), 400

    required_fields = ['prediction', 'prediction_label', 'probability', 'payload']
    missing = [field for field in required_fields if field not in payload]
    if missing:
        return jsonify({'error': f'Campos faltando: {missing}'}), 400

    result_payload = {
        'prediction': payload['prediction'],
        'prenhez': payload['prediction_label'],
        'confidence': payload['probability'],
        'confidence_percent': round(float(payload['probability']) * 100, 2),
    }

    try:
        record = persist_analysis(
            payload['payload'],
            result_payload,
            status=payload.get('status', 'manual'),
            notes=payload.get('notes'),
        )
        return jsonify({'analysis': serialize_analysis(record)}), 201
    except Exception as exc:
        log_status("CRUD", f"Erro ao criar análise manual: {exc}", "❌")
        return jsonify({'error': 'Erro ao salvar análise manual'}), 500


@app.route('/analises/<int:analysis_id>', methods=['GET'])
def retrieve_analysis(analysis_id: int):
    session = get_session()
    try:
        record = session.get(AnalysisRecord, analysis_id)
        if not record:
            return jsonify({'error': 'Análise não encontrada'}), 404
        log_status("CRUD", f"Análise #{analysis_id} carregada", "📄")
        return jsonify(serialize_analysis(record))
    finally:
        session.close()


@app.route('/predict/<int:analysis_id>', methods=['GET', 'PUT', 'DELETE'])
def legacy_predict_detail(analysis_id: int):
    if request.method == 'GET':
        return retrieve_analysis(analysis_id)
    if request.method == 'PUT':
        return update_analysis(analysis_id)
    if request.method == 'DELETE':
        return delete_analysis(analysis_id)
    return jsonify({'error': 'Método não suportado'}), 405


@app.route('/analises/<int:analysis_id>', methods=['PUT'])
def update_analysis(analysis_id: int):
    payload = request.get_json() or {}
    session = get_session()
    try:
        record = session.get(AnalysisRecord, analysis_id)
        if not record:
            return jsonify({'error': 'Análise não encontrada'}), 404

        if 'status' in payload:
            record.status = payload['status']
        if 'notes' in payload:
            record.notes = payload['notes']
        if 'cow_id' in payload:
            record.cow_id = str(payload['cow_id'])
        if 'payload' in payload:
            record.payload = sanitize_payload(payload['payload'])

        session.commit()
        session.refresh(record)
        log_status("CRUD", f"Análise #{analysis_id} atualizada", "✅")
        return jsonify(serialize_analysis(record))
    except SQLAlchemyError as exc:
        session.rollback()
        log_status("CRUD", f"Erro ao atualizar análise #{analysis_id}: {exc}", "❌")
        return jsonify({'error': 'Erro ao atualizar análise'}), 500
    finally:
        session.close()


@app.route('/analises/<int:analysis_id>', methods=['DELETE'])
def delete_analysis(analysis_id: int):
    session = get_session()
    try:
        record = session.get(AnalysisRecord, analysis_id)
        if not record:
            return jsonify({'error': 'Análise não encontrada'}), 404
        session.delete(record)
        session.commit()
        log_status("CRUD", f"Análise #{analysis_id} removida", "🗑️")
        return jsonify({'status': 'deleted', 'analysis_id': analysis_id})
    except SQLAlchemyError as exc:
        session.rollback()
        log_status("CRUD", f"Erro ao remover análise #{analysis_id}: {exc}", "❌")
        return jsonify({'error': 'Erro ao remover análise'}), 500
    finally:
        session.close()


@app.route('/analises', methods=['DELETE'])
def delete_all_analyses():
    session = get_session()
    try:
        deleted = session.query(AnalysisRecord).delete()
        session.commit()
        log_status("CRUD", f"{deleted} análises removidas em massa", "🗑️")
        return jsonify({'deleted': deleted})
    except SQLAlchemyError as exc:
        session.rollback()
        log_status("CRUD", f"Erro ao limpar análises: {exc}", "❌")
        return jsonify({'error': 'Erro ao limpar histórico'}), 500
    finally:
        session.close()


@app.route('/cows/<cow_id>/history', methods=['GET'])
def cow_history(cow_id: str):
    session = get_session()
    limit = min(request.args.get('limit', type=int) or 500, 500)
    offset = request.args.get('offset', type=int) or 0
    
    try:
        base_query = session.query(AnalysisRecord).filter(AnalysisRecord.cow_id == str(cow_id))
        total_count = base_query.count()
        
        if total_count == 0:
            return jsonify({
                'data': [],
                'total': 0,
                'limit': limit,
                'offset': 0,
                'has_more': False
            })
        
        records = (
            base_query
            .order_by(AnalysisRecord.id.desc())
            .limit(limit)
            .offset(offset)
            .all()
        )
        
        records_sorted = sorted(records, key=lambda r: r.created_at if r.created_at else r.id, reverse=True)
        
        log_status("CRUD", f"Histórico da vaca {cow_id}: {len(records_sorted)} análises (total: {total_count})", "📚")
        return jsonify({
            'data': [serialize_analysis(record) for record in records_sorted],
            'total': total_count,
            'limit': limit,
            'offset': offset,
            'has_more': (offset + len(records_sorted)) < total_count
        })
    except SQLAlchemyError as exc:
        session.rollback()
        log_status("CRUD", f"Erro ao buscar histórico da vaca {cow_id}: {exc}", "❌")
        return jsonify({'error': f'Erro ao buscar histórico: {str(exc)}'}), 500
    except Exception as exc:
        log_status("CRUD", f"Erro inesperado ao buscar histórico da vaca {cow_id}: {exc}", "❌")
        return jsonify({'error': f'Erro inesperado: {str(exc)}'}), 500
    finally:
        session.close()


if __name__ == '__main__':
    log_status("BOOT", "API Iniciando...", "🚀")
    log_status("BOOT", f"Features do modelo: {model_features}", "📋")
    log_status("BOOT", f"Número de features: {len(model_features)}", "🔢")
    app.run(host='0.0.0.0', port=5000, debug=True)