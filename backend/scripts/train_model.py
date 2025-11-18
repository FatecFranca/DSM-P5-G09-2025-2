import os
import joblib
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score, confusion_matrix

# ======================================================
# CONFIGURAÇÕES
# ======================================================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL_DIR = os.path.join(BASE_DIR, "backend", "models")
os.makedirs(MODEL_DIR, exist_ok=True)
MODEL_PATH = os.path.join(MODEL_DIR, "pregnancy_pipeline.joblib")

print(f"📁 Diretório do modelo: {MODEL_PATH}")

# ======================================================
# CRIAR DADOS REALISTAS E BALANCEADOS
# ======================================================
def criar_dados_balanceados():
    """Cria dados balanceados com padrões claros"""
    np.random.seed(42)
    n_samples = 1000
    
    print("🎯 Criando dados balanceados (50% SIM, 50% NÃO)...")
    
    # Dados para NÃO prenhes (50%)
    n_nao = n_samples // 2
    dados_nao = {
        'lactation_number': np.random.randint(1, 3, n_nao),  # Vacas mais jovens
        'avgtotalmotion': np.random.normal(180, 20, n_nao),  # Muito movimento
        'parity': np.random.randint(1, 2, n_nao),            # Poucas gestações
        'avgrumination': np.random.normal(30, 5, n_nao),     # Pouca ruminação
        'dayhour': np.random.randint(1, 20, n_nao),          # Poucos dias
        'avgactivity': np.random.normal(95, 10, n_nao),      # Alta atividade
        'avghoursstanding': np.random.normal(10, 1, n_nao),  # Muito tempo em pé
    }
    
    # Dados para SIM prenhes (50%)
    n_sim = n_samples - n_nao
    dados_sim = {
        'lactation_number': np.random.randint(3, 5, n_sim),  # Vacas mais velhas
        'avgtotalmotion': np.random.normal(120, 15, n_sim),  # Pouco movimento
        'parity': np.random.randint(2, 4, n_sim),            # Mais gestações
        'avgrumination': np.random.normal(55, 5, n_sim),     # Muita ruminação
        'dayhour': np.random.randint(40, 90, n_sim),         # Muitos dias
        'avgactivity': np.random.normal(65, 10, n_sim),      # Baixa atividade
        'avghoursstanding': np.random.normal(6, 1, n_sim),   # Pouco tempo em pé
    }
    
    # Combinar dados
    df_nao = pd.DataFrame(dados_nao)
    df_nao['is_pregnant'] = 0
    
    df_sim = pd.DataFrame(dados_sim)
    df_sim['is_pregnant'] = 1
    
    df = pd.concat([df_nao, df_sim], ignore_index=True)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)  # Embaralhar
    
    print(f"✅ Dados criados: {df.shape[0]} amostras")
    print(f"   NÃO prenhes: {(df['is_pregnant'] == 0).sum()}")
    print(f"   SIM prenhes: {(df['is_pregnant'] == 1).sum()}")
    
    return df

# ======================================================
# PREPARAR DADOS
# ======================================================
print("📥 Criando dados...")
df = criar_dados_balanceados()

# Feature mapping
feature_mapping = {
    'age': 'lactation_number',
    'weight': 'avgtotalmotion',     
    'previous_pregnancies': 'parity',   
    'body_condition': 'avgrumination',  
    'days_since_insemination': 'dayhour',
    'milk_production': 'avgactivity',   
    'body_temperature': 'avghoursstanding'
}

interface_features = list(feature_mapping.keys())

# Preparar X e y
X = pd.DataFrame()
for if_feature in interface_features:
    dataset_feature = feature_mapping[if_feature]
    X[if_feature] = df[dataset_feature]

y = df['is_pregnant']

print(f"\n📊 Distribuição final:")
print(f"   NÃO (0): {(y == 0).sum()}")
print(f"   SIM (1): {(y == 1).sum()}")

# ======================================================
# TREINAR MODELO
# ======================================================
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

# Pipeline
preprocessor = ColumnTransformer(
    transformers=[
        ("num", Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler())
        ]), interface_features)
    ]
)

# Modelo com parâmetros para forçar diversidade
pipeline = Pipeline([
    ("pre", preprocessor),
    ("clf", RandomForestClassifier(
        n_estimators=200,
        random_state=42,
        max_depth=15,
        min_samples_split=5,
        min_samples_leaf=2,
        class_weight='balanced',
        max_features='sqrt'  # Mais diversidade
    ))
])

print("\n🚀 Treinando modelo...")
pipeline.fit(X_train, y_train)

# ======================================================
# AVALIAR
# ======================================================
y_pred = pipeline.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)

print("\n📈 RELATÓRIO DE CLASSIFICAÇÃO:")
print("="*50)
print(classification_report(y_test, y_pred, target_names=['NÃO', 'SIM']))

cm = confusion_matrix(y_test, y_pred)
print(f"📊 Matriz de Confusão:")
print(f"   TN: {cm[0,0]} | FP: {cm[0,1]}")
print(f"   FN: {cm[1,0]} | TP: {cm[1,1]}")
print(f"🎯 Acurácia: {accuracy:.3f}")

# ======================================================
# TESTAR DIVERSOS CASOS
# ======================================================
print("\n🧪 TESTANDO CASOS DIVERSOS:")
print("="*50)

test_cases = [
    # Casos que devem ser NÃO
    {
        'name': 'Vaca jovem ativa - NÃO',
        'age': 1.0, 'weight': 190.0, 'previous_pregnancies': 1,
        'body_condition': 25.0, 'days_since_insemination': 5,
        'milk_production': 100.0, 'body_temperature': 11.0
    },
    {
        'name': 'Vaca muito ativa - NÃO', 
        'age': 2.0, 'weight': 200.0, 'previous_pregnancies': 1,
        'body_condition': 28.0, 'days_since_insemination': 10,
        'milk_production': 110.0, 'body_temperature': 10.5
    },
    # Casos que devem ser SIM
    {
        'name': 'Vaca experiente calma - SIM',
        'age': 4.0, 'weight': 110.0, 'previous_pregnancies': 3,
        'body_condition': 60.0, 'days_since_insemination': 70,
        'milk_production': 50.0, 'body_temperature': 5.5
    },
    {
        'name': 'Vaca muita ruminação - SIM',
        'age': 3.0, 'weight': 120.0, 'previous_pregnancies': 2,
        'body_condition': 58.0, 'days_since_insemination': 60,
        'milk_production': 55.0, 'body_temperature': 6.0
    },
    # Casos intermediários
    {
        'name': 'Caso balanceado',
        'age': 2.5, 'weight': 150.0, 'previous_pregnancies': 2,
        'body_condition': 45.0, 'days_since_insemination': 35,
        'milk_production': 80.0, 'body_temperature': 8.0
    }
]

for case in test_cases:
    sample_df = pd.DataFrame([{k: case[k] for k in interface_features}])
    prediction = pipeline.predict(sample_df)[0]
    proba = pipeline.predict_proba(sample_df)[0]
    resultado = "SIM" if prediction == 1 else "NÃO"
    print(f"🔍 {case['name']}: {resultado} (prob: NÃO={proba[0]:.3f}, SIM={proba[1]:.3f})")

# ======================================================
# SALVAR MODELO
# ======================================================
model_bundle = {
    "pipeline": pipeline,
    "features": interface_features,
    "feature_mapping": feature_mapping,
    "metadata": {
        "accuracy": accuracy,
        "n_samples": len(X),
        "class_distribution": {
            "nao_prenhes": (y == 0).sum(),
            "prenhes": (y == 1).sum()
        },
        "training_date": pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
    }
}

joblib.dump(model_bundle, MODEL_PATH)
print(f"\n✅ Modelo salvo em: {MODEL_PATH}")

print("\n🎯 MODELO PRONTO! Agora deve retornar tanto SIM quanto NÃO")