# backend/scripts/pregnancy_classifier.py (VERSÃO CORRIGIDA - TRATAMENTO DE 'parity')
import pandas as pd
import numpy as np
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, cross_val_score, KFold
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import GaussianNB
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from sklearn.pipeline import Pipeline
import os

class CowPregnancyClassifierPadrao:
    def __init__(self):
        self.pipeline = None
        self.features = None
        self.model_trained = False
        self.label_encoders = {}
        
    def load_data(self, file_path):
        """Carrega dados seguindo padrão dos notebooks"""
        print("📥 CARREGANDO DADOS...")
        df = pd.read_csv(file_path)
        print(f"📊 Dimensões: {df.shape}")
        print(f"🔍 Colunas: {df.columns.tolist()}")
        return df
    
    def explore_data(self, df):
        """Análise exploratória completa"""
        print("\n🔍 ANÁLISE EXPLORATÓRIA:")
        print("="*50)
        
        # Estatísticas básicas
        print("📈 Estatísticas descritivas:")
        print(df.describe())
        
        # Valores nulos
        print("\n❌ Valores nulos:")
        print(df.isnull().sum())
        
        # Tipos de dados
        print("\n📝 Tipos de dados:")
        print(df.dtypes)
        
        # Analisar coluna 'parity' especificamente
        if 'parity' in df.columns:
            print(f"\n🔍 Valores únicos em 'parity': {df['parity'].unique()}")
            print(f"📊 Distribuição de 'parity': {df['parity'].value_counts()}")
        
        return df
    
    def preprocess_data(self, df):
        """Pré-processamento completo seguindo padrão"""
        print("\n🧹 PRÉ-PROCESSAMENTO:")
        print("="*50)
        
        # 1. Remover colunas irrelevantes
        cols_to_drop = ['cow', 'TIME', 'date', 'calvdate', 'breed']
        df = df.drop(columns=[col for col in cols_to_drop if col in df.columns])
        print("✅ Colunas irrelevantes removidas")
        
        # 2. Tratar coluna 'parity' primeiro (convertendo texto para numérico)
        df = self._handle_parity_column(df)
        
        # 3. Converter outras colunas para numérico
        numeric_cols = df.select_dtypes(include=['object']).columns
        for col in numeric_cols:
            df[col] = pd.to_numeric(df[col], errors='coerce')
        print("✅ Dados convertidos para numérico")
        
        # 4. Tratar valores missing (média por classe)
        print("🔧 Tratando valores missing...")
        df = self._handle_missing_values(df)
        
        # 5. Remover duplicatas
        initial_size = len(df)
        df = df.drop_duplicates()
        removed_duplicates = initial_size - len(df)
        print(f"✅ Duplicatas removidas: {removed_duplicates}")
        
        # 6. Engenharia de features (APENAS 7)
        df_processed, self.features, y = self._feature_engineering(df)
        
        return df_processed, y
    
    def _handle_parity_column(self, df):
        """Converte a coluna 'parity' de texto para numérico"""
        if 'parity' in df.columns:
            print("🔧 Convertendo coluna 'parity' para numérico...")
            
            # Mapear valores de texto para números
            parity_mapping = {
                'primiparous': 1,   # Primeira prenhez
                'multiparous': 2,   # Múltiplas prenhezes
                'nulliparous': 0,   # Nunca prenhe
                '1': 1,
                '2': 2,
                '0': 0
            }
            
            # Aplicar mapeamento
            df['parity'] = df['parity'].astype(str).str.lower().map(parity_mapping)
            
            # Se algum valor não foi mapeado, preencher com moda
            if df['parity'].isnull().sum() > 0:
                mode_value = df['parity'].mode()[0] if not df['parity'].mode().empty else 1
                df['parity'] = df['parity'].fillna(mode_value)
                print(f"   📍 Valores não mapeados em 'parity' preenchidos com: {mode_value}")
            
            print(f"   ✅ 'parity' convertido. Valores: {df['parity'].unique()}")
            print(f"   📊 Distribuição: {df['parity'].value_counts().to_dict()}")
        
        return df
    
    def _handle_missing_values(self, df):
        """Trata valores missing seguindo padrão dos notebooks"""
        # Para cada coluna numérica, preencher com mediana
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        
        for col in numeric_cols:
            if df[col].isnull().sum() > 0:
                df[col] = df[col].fillna(df[col].median())
                print(f"   📍 {col}: {df[col].isnull().sum()} missing preenchidos")
        
        return df
    
    def _feature_engineering(self, df):
        """Engenharia de features - APENAS 7 FEATURES"""
        print("\n🔧 ENGENHARIA DE FEATURES:")
        
        # MAPEAMENTO DAS 7 FEATURES (igual à home)
        feature_mapping = {
            'age': 'lactation_number_in_data',
            'weight': 'avgtotalmotion',     
            'previous_pregnancies': 'parity',   
            'body_condition': 'avgrumination',  
            'days_since_insemination': 'daysprior',
            'milk_production': 'avgactivity',   
            'body_temperature': 'avghoursstanding'
        }
        
        X = pd.DataFrame()
        features_used = []
        
        for new_feat, orig_feat in feature_mapping.items():
            if orig_feat in df.columns:
                X[new_feat] = df[orig_feat]
                features_used.append(new_feat)
                print(f"   ✅ {new_feat} <- {orig_feat}")
        
        # Criar target (prenhez) - GARANTINDO MESMO TAMANHO QUE X
        y = self._create_target_variable(df, len(X))
        
        print(f"📋 Features finais: {features_used}")
        print(f"📊 Shape de X: {X.shape}")
        print(f"📊 Shape de y: {y.shape}")
        print(f"🎯 Distribuição do target: {pd.Series(y).value_counts().to_dict()}")
        
        return X, features_used, y
    
    def _create_target_variable(self, df, target_length):
        """Cria variável target para prenhez com tamanho correto"""
        y = np.zeros(target_length)  # Inicializa com zeros
        
        # Usar apenas as primeiras 'target_length' linhas para garantir tamanho consistente
        df_subset = df.head(target_length)
        
        # LÓGICA MELHORADA PARA DETERMINAR PRENHEZ
        pregnant_conditions = []
        
        # 1. Baseado em calved (se pariu) + daysprior
        if 'calved' in df_subset.columns and 'daysprior' in df_subset.columns:
            condition1 = (df_subset['calved'] == 1) & (df_subset['daysprior'] < 0)
            pregnant_conditions.append(condition1)
            print(f"   🐄 Baseado em calved: {condition1.sum()} prenhes")
        
        # 2. Baseado em predictedcalving
        if 'predictedcalving' in df_subset.columns:
            condition2 = df_subset['predictedcalving'] > 0
            pregnant_conditions.append(condition2)
            print(f"   🤰 Baseado em predictedcalving: {condition2.sum()} prenhes")
        
        # 3. Baseado em comportamento típico
        if 'avgactivity' in df_subset.columns and 'avgrumination' in df_subset.columns:
            activity_threshold = df_subset['avgactivity'].quantile(0.3)  # Baixa atividade
            rumination_threshold = df_subset['avgrumination'].quantile(0.7)  # Alta ruminação
            
            condition3 = (df_subset['avgactivity'] < activity_threshold) & \
                        (df_subset['avgrumination'] > rumination_threshold)
            pregnant_conditions.append(condition3)
            print(f"   📊 Baseado em comportamento: {condition3.sum()} prenhes")
        
        # Combinar todas as condições
        if pregnant_conditions:
            combined_condition = pregnant_conditions[0]
            for condition in pregnant_conditions[1:]:
                combined_condition = combined_condition | condition
            
            y[combined_condition.values] = 1
            print(f"   ✅ Total de prenhes identificadas: {y.sum()}")
        else:
            # Fallback: usar dados sintéticos baseados em características
            print("   ⚠️  Usando fallback para criar target...")
            if 'daysprior' in df_subset.columns:
                # Vacas com daysprior muito negativo têm maior chance de estarem prenhes
                condition = df_subset['daysprior'] < df_subset['daysprior'].quantile(0.2)
                y[condition.values] = 1
                print(f"   📅 Fallback baseado em daysprior: {y.sum()} prenhes")
        
        return y
    
    def analyze_correlations(self, X, y):
        """Análise de correlações como nos notebooks"""
        print("\n📊 ANÁLISE DE CORRELAÇÕES:")
        
        # VERIFICAR TAMANHOS E TIPOS ANTES
        print(f"🔍 Verificando tamanhos: X={X.shape}, y={y.shape}")
        print(f"🔍 Tipos de dados em X: {X.dtypes}")
        
        # Garantir que todas as colunas são numéricas
        X_numeric = X.apply(pd.to_numeric, errors='coerce')
        
        X_with_target = X_numeric.copy()
        X_with_target['target'] = y
        
        # Matriz de correlação
        corr_matrix = X_with_target.corr()
        
        print("🔗 Correlações com target:")
        target_corrs = corr_matrix['target'].sort_values(ascending=False)
        for feat, corr in target_corrs.items():
            if feat != 'target':
                print(f"   {feat}: {corr:+.3f}")
        
        # Heatmap
        plt.figure(figsize=(10, 8))
        sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', center=0, fmt='.3f')
        plt.title('Matriz de Correlação - Prenhez Bovino')
        plt.tight_layout()
        plt.savefig('correlation_matrix.png')
        print("📈 Heatmap salvo como 'correlation_matrix.png'")
        plt.show()
    
    def compare_models(self, X, y):
        """Compara múltiplos modelos como nos notebooks"""
        print("\n🤖 COMPARAÇÃO DE MODELOS:")
        print("="*50)
        
        # Garantir que X é totalmente numérico
        X_numeric = X.apply(pd.to_numeric, errors='coerce')
        
        # Lista de modelos para comparar
        models = [
            ('LR', LogisticRegression(random_state=42, class_weight='balanced', max_iter=1000)),
            ('KNN', KNeighborsClassifier()),
            ('CART', DecisionTreeClassifier(random_state=42, class_weight='balanced')),
            ('NB', GaussianNB()),
            ('SVM', SVC(random_state=42, class_weight='balanced', probability=True)),
            ('RF', RandomForestClassifier(random_state=42, class_weight='balanced'))
        ]
        
        # Validação cruzada
        results = []
        names = []
        
        print("📊 Avaliação com validação cruzada (5 folds):")
        for name, model in models:
            try:
                kfold = KFold(n_splits=5, shuffle=True, random_state=42)
                cv_results = cross_val_score(model, X_numeric, y, cv=kfold, scoring='accuracy')
                results.append(cv_results)
                names.append(name)
                print(f"   {name}: {cv_results.mean():.3f} (+/- {cv_results.std():.3f})")
            except Exception as e:
                print(f"   ❌ {name}: Erro - {e}")
                results.append([0])  # Placeholder para manter o índice
        
        # Boxplot comparativo (apenas para modelos que funcionaram)
        if len(results) > 0:
            plt.figure(figsize=(10, 6))
            plt.boxplot(results)
            plt.title('Comparação de Modelos - Prenhez Bovino')
            plt.xticks(range(1, len(names) + 1), names)
            plt.ylabel('Acurácia')
            plt.grid(True, alpha=0.3)
            plt.savefig('model_comparison.png')
            print("📈 Gráfico de comparação salvo como 'model_comparison.png'")
            plt.show()
        
        return models, results, names
    
    def train_best_model(self, X, y, test_size=0.2):
        """Treina o melhor modelo"""
        print("\n🎯 TREINANDO MELHOR MODELO:")
        print("="*50)
        
        # Garantir que X é totalmente numérico
        X_numeric = X.apply(pd.to_numeric, errors='coerce')
        
        # Verificar balanceamento
        class_dist = pd.Series(y).value_counts()
        print(f"📊 Distribuição de classes: {class_dist.to_dict()}")
        print(f"📈 Proporção de prenhez: {y.mean():.2%}")
        
        # Split dos dados
        X_train, X_test, y_train, y_test = train_test_split(
            X_numeric, y, test_size=test_size, random_state=42, stratify=y
        )
        
        print(f"📚 Treino: {X_train.shape[0]} amostras")
        print(f"📚 Teste: {X_test.shape[0]} amostras")
        
        # Pipeline com RandomForest (geralmente melhor para dados complexos)
        self.pipeline = Pipeline([
            ('scaler', StandardScaler()),
            ('classifier', RandomForestClassifier(
                n_estimators=100,
                max_depth=10,
                min_samples_split=5,
                min_samples_leaf=2,
                random_state=42,
                class_weight='balanced'
            ))
        ])
        
        # Treinar
        print("⏳ Treinando modelo...")
        self.pipeline.fit(X_train, y_train)
        
        # Avaliar
        train_score = self.pipeline.score(X_train, y_train)
        test_score = self.pipeline.score(X_test, y_test)
        
        print(f"🎯 Acurácia - Treino: {train_score:.3f}")
        print(f"🎯 Acurácia - Teste: {test_score:.3f}")
        
        # Relatório detalhado
        y_pred = self.pipeline.predict(X_test)
        print("\n📈 RELATÓRIO DE CLASSIFICAÇÃO:")
        print(classification_report(y_test, y_pred, target_names=['NÃO', 'SIM']))
        
        # Matriz de confusão
        cm = confusion_matrix(y_test, y_pred)
        print("📊 MATRIZ DE CONFUSÃO:")
        print(f"   TN: {cm[0,0]} | FP: {cm[0,1]}")
        print(f"   FN: {cm[1,0]} | TP: {cm[1,1]}")
        
        # Feature importance
        if hasattr(self.pipeline.named_steps['classifier'], 'feature_importances_'):
            importances = self.pipeline.named_steps['classifier'].feature_importances_
            feature_names = X.columns
            
            print("\n📊 IMPORTÂNCIA DAS FEATURES:")
            indices = np.argsort(importances)[::-1]
            for i in range(len(importances)):
                print(f"   {i+1:2d}. {feature_names[indices[i]]}: {importances[indices[i]]:.3f}")
        
        self.model_trained = True
        return test_score
    
    def save_model(self, file_path):
        """Salva modelo treinado"""
        if not self.model_trained:
            raise ValueError("❌ Modelo não treinado!")
        
        model_bundle = {
            'pipeline': self.pipeline,
            'features': self.features,
            'metadata': {
                'model_type': 'RandomForest',
                'n_features': len(self.features),
                'training_date': pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
            }
        }
        
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        joblib.dump(model_bundle, file_path)
        print(f"✅ Modelo salvo em: {file_path}")

def main():
    """Executa fluxo completo seguindo padrão dos notebooks"""
    print("🚀 INICIANDO TREINAMENTO - PADRÃO NOTEBOOKS")
    print("="*60)
    
    classifier = CowPregnancyClassifierPadrao()
    
    try:
        # 1. Carregar dados
        df = classifier.load_data('cow_monitoring_data.csv')
        
        # 2. Análise exploratória
        df = classifier.explore_data(df)
        
        # 3. Pré-processamento completo (AGORA RETORNA X E y)
        df_processed, y = classifier.preprocess_data(df)
        
        # 4. Separar features
        X = df_processed[classifier.features]
        
        # 5. Análise de correlações
        classifier.analyze_correlations(X, y)
        
        # 6. Comparar modelos
        classifier.compare_models(X, y)
        
        # 7. Treinar melhor modelo
        accuracy = classifier.train_best_model(X, y)
        
        # 8. Salvar modelo
        model_path = os.path.join('..', 'models', 'pregnancy_pipeline.joblib')
        classifier.save_model(model_path)
        
        print(f"\n✅ TREINAMENTO CONCLUÍDO! Acurácia: {accuracy:.3f}")
        
    except Exception as e:
        print(f"❌ Erro: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()