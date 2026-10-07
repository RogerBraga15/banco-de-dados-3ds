CREATE DATABASE IF NOT EXISTS loja_roupas3ds;
use loja_roupas3ds;

CREATE TABLE clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    cpf VARCHAR(14) UNIQUE,
    telefone VARCHAR(20),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE produtos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    marca VARCHAR(50),
    preco_base DECIMAL(10, 2) NOT NULL,
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE RESTRICT
);

CREATE TABLE variacoes_produto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    produto_id INT NOT NULL,
    tamanho VARCHAR(10) NOT NULL, -- Ex: PP, P, M, G, GG, 38, 40, 42
    cor VARCHAR(30) NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    quantidade_estoque INT NOT NULL DEFAULT 0,
    preco DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE
);

CREATE TABLE pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pendente', 'pago', 'enviado', 'entregue', 'cancelado') DEFAULT 'pendente',
    valor_total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT
);

CREATE TABLE itens_pedido (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    variacao_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (variacao_id) REFERENCES variacoes_produto(id) ON DELETE RESTRICT
);

DELIMITER //

CREATE TRIGGER trg_validar_estoque_antes_venda
BEFORE INSERT ON itens_pedido
FOR EACH ROW
BEGIN
    DECLARE estoque_atual INT;

    -- Busca o estoque atual da variação do produto
    SELECT quantidade_estoque INTO estoque_atual
    FROM variacoes_produto
    WHERE id = NEW.variacao_id;

    -- Se o estoque for menor do que o pedido, cancela a operação
    IF estoque_atual < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Estoque insuficiente para esta variação de produto.';
    END IF;
END //

DELIMITER ;