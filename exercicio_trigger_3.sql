CREATE TABLE funcionarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    salario DECIMAL(10, 2) NOT NULL
);

CREATE TABLE historico_carreira (
    id INT AUTO_INCREMENT PRIMARY KEY,
    funcionario_id INT NOT NULL,
    cargo_antigo VARCHAR(50),
    cargo_novo VARCHAR(50),
    salario_antigo DECIMAL(10, 2),
    salario_novo DECIMAL(10, 2),
    data_alteracao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id) ON DELETE CASCADE
);

DELIMITER $$

CREATE TRIGGER tg_auditoria_carreira
AFTER UPDATE ON funcionarios
FOR EACH ROW
BEGIN
    IF (OLD.cargo <> NEW.cargo) OR (OLD.salario <> NEW.salario) THEN
        INSERT INTO historico_carreira (
            funcionario_id, 
            cargo_antigo, 
            cargo_novo, 
            salario_antigo, 
            salario_novo
        ) VALUES (
            OLD.id, 
            OLD.cargo, 
            NEW.cargo, 
            OLD.salario, 
            NEW.salario
        );
    END IF;
END$$

DELIMITER ;

INSERT INTO funcionarios (nome, cargo, salario) 
VALUES ('Maria Santos', 'Desenvolvedora Jr', 3500.00);

UPDATE funcionarios 
SET cargo = 'Desenvolvedora Pleno', salario = 5500.00 
WHERE nome = 'Maria Santos';

SELECT * FROM historico_carreira;