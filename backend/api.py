# backend/api.py
import os
import joblib
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Carregar modelo
MODEL_PATH = "models\pregnancy_pipeline.joblib"

try:
    model_bundle = joblib.load(MODEL_PATH)
    pipeline = model_bundle['pipeline']
    features = model_bundle['features']
    modelo_carregado = True
    print(f"✅ Modelo carregado com features: {features}")
except Exception as e:
    print(f"❌ Erro ao carregar modelo: {e}")
    pipeline, features = None, []
    modelo_carregado = False

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'online',
        'model_loaded': modelo_carregado,
        'features': features
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Faz predição de prenhez - retorna SIM ou NÃO"""
    if not modelo_carregado:
        return jsonify({'error': 'Modelo não carregado'}), 500
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Dados JSON necessários'}), 400
        
        print(f"📥 Dados recebidos: {data}")
        
        # Verificar features obrigatórias
        missing_features = [f for f in features if f not in data]
        if missing_features:
            return jsonify({
                'error': 'Features faltando',
                'missing': missing_features,
                'required': features
            }), 400
        
        # Preparar dados
        input_data = {feature: [float(data[feature])] for feature in features}
        df_input = pd.DataFrame(input_data)
        
        # Fazer predição
        prediction = pipeline.predict(df_input)[0]
        probabilities = pipeline.predict_proba(df_input)[0]
        
        # Converter para resposta
        resultado = "SIM" if prediction == 1 else "NÃO"
        confianca = probabilities[1] if prediction == 1 else probabilities[0]
        
        response = {
            'prenhez': resultado,
            'confidence': float(confianca),
            'probabilities': {
                'NAO': float(probabilities[0]),
                'SIM': float(probabilities[1])
            },
            'status': 'success'
        }
        
        print(f"🎯 Predição: {resultado} (Confiança: {confianca:.3f})")
        return jsonify(response)
        
    except Exception as e:
        print(f"❌ Erro na predição: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)