# backend/app.py
import os
import joblib
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configurações
MODEL_PATH = os.path.join('models', 'pregnancy_pipeline.joblib')

def carregar_modelo():
    """Carrega o modelo treinado"""
    try:
        model_bundle = joblib.load(MODEL_PATH)
        pipeline = model_bundle["pipeline"]
        features = model_bundle["features"]
        metadata = model_bundle.get("metadata", {})
        
        print(f"✅ Modelo carregado:")
        print(f"   - Features: {features}")
        print(f"   - Tipo: {metadata.get('model_type', 'N/A')}")
        print(f"   - Número de features: {len(features)}")
        
        return pipeline, features, metadata
    except Exception as e:
        print(f"❌ Erro ao carregar modelo: {str(e)}")
        return None, [], {}

# Carregar modelo ao iniciar
pipeline, model_features, model_metadata = carregar_modelo()
modelo_carregado = pipeline is not None

@app.route('/health', methods=['GET'])
def health_check():
    """Verifica status da API"""
    return jsonify({
        'status': 'online',
        'model_loaded': modelo_carregado,
        'features_esperadas': model_features,
        'model_metadata': model_metadata
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Faz predição de prenhez - retorna apenas SIM ou NÃO"""
    if not modelo_carregado:
        return jsonify({'error': 'Modelo não carregado'}), 500
    
    try:
        # Obter dados do request
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Dados JSON necessários'}), 400
        
        print(f"📥 Dados recebidos: {data}")
        
        # Verificar features obrigatórias
        missing_features = [f for f in model_features if f not in data]
        if missing_features:
            return jsonify({
                'error': 'Features faltando',
                'missing': missing_features,
                'required': model_features
            }), 400
        
        # Preparar dados para predição
        input_data = {feature: [float(data[feature])] for feature in model_features}
        df_input = pd.DataFrame(input_data)
        
        # Fazer predição (apenas SIM ou NÃO)
        prediction = int(pipeline.predict(df_input)[0])
        
        # Pegar confiabilidade REAL usando predict_proba
        try:
            proba = pipeline.predict_proba(df_input)[0][1]  # prob de prenhez
        except Exception as e:
            print(f"⚠️ Não foi possível calcular confiabilidade: {e}")
            proba = 0.5  # Valor neutro quando não consegue calcular

        # Converter para resposta legível
        resultado = "SIM" if prediction == 1 else "NÃO"
        
        response = {
            'prenhez': resultado,
            'prediction': prediction,
            'confidence': float(proba),
            'confidence_percent': round(float(proba) * 100, 2),
            'status': 'success'
        }
        
        print(f"📊 Resultado: {resultado} | 🔍 Confiabilidade: {response['confidence_percent']}%")
        return jsonify(response)
        
    except Exception as e:
        print(f"❌ Erro na predição: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/features', methods=['GET'])
def get_features():
    """Retorna as features esperadas pelo modelo"""
    return jsonify({
        'features': model_features,
        'model_metadata': model_metadata
    })

if __name__ == '__main__':
    print(f"🚀 API Iniciando...")
    print(f"📋 Features do modelo: {model_features}")
    print(f"🔢 Número de features: {len(model_features)}")
    app.run(host='0.0.0.0', port=5000, debug=True)