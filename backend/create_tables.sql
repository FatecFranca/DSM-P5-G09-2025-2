-- cria tabela para armazenar previsões (opcional)
CREATE TABLE IF NOT EXISTS calving_predictions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cow VARCHAR(64),
  prediction TINYINT,
  probability FLOAT,
  features JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
