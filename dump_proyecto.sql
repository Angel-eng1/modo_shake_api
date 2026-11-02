-- Dump de esquema y datos de demostración de Modo Shake
-- Ejecutar en MySQL o DBeaver sobre una base de prueba.
-- Contiene DDL y DML; las consultas de verificación del avance no se incluyen.
CREATE DATABASE IF NOT EXISTS modo_shake
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE modo_shake;

-- Categorías
CREATE TABLE IF NOT EXISTS categorias (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL UNIQUE,
  descripcion VARCHAR(180)
) ENGINE=InnoDB;

-- Clientes
CREATE TABLE IF NOT EXISTS clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL,
  telefono VARCHAR(20),
  correo VARCHAR(120) UNIQUE
) ENGINE=InnoDB;

-- Perfiles del sistema
CREATE TABLE IF NOT EXISTS roles (
  id_rol TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(20) NOT NULL UNIQUE,
  descripcion VARCHAR(150),
  CONSTRAINT ck_roles_nombre
    CHECK (nombre IN ('ADMIN', 'USUARIO'))
) ENGINE=InnoDB;

-- Perfiles con identificadores fijos para relacionarlos con empleados
INSERT IGNORE INTO roles (id_rol, nombre, descripcion) VALUES
  (1, 'ADMIN', 'Administra el sistema y consulta inventario y ventas'),
  (2, 'USUARIO', 'Gestiona operaciones sin acceso a inventario ni ventas');

-- Empleados que usarán el sistema
CREATE TABLE IF NOT EXISTS empleados (
  id_empleado INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(60) NOT NULL,
  apellido VARCHAR(60) NOT NULL,
  telefono VARCHAR(20),
  puesto VARCHAR(40) NOT NULL,
  id_rol TINYINT UNSIGNED NOT NULL,
  usuario VARCHAR(40) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  estado VARCHAR(15) NOT NULL DEFAULT 'Activo',
  CONSTRAINT ck_empleados_estado
    CHECK (estado IN ('Activo', 'Inactivo')),
  CONSTRAINT fk_empleados_rol
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
) ENGINE=InnoDB;

-- Productos ofrecidos por el restaurante
CREATE TABLE IF NOT EXISTS productos (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  id_categoria INT NOT NULL,
  nombre VARCHAR(90) NOT NULL UNIQUE,
  descripcion VARCHAR(220),
  precio DECIMAL(10,2) NOT NULL,
  estado VARCHAR(15) NOT NULL DEFAULT 'Activo',
  CONSTRAINT ck_productos_precio CHECK (precio >= 0),
  CONSTRAINT ck_productos_estado
    CHECK (estado IN ('Activo', 'Inactivo')),
  CONSTRAINT fk_productos_categoria
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
) ENGINE=InnoDB;

-- Insumos y materias primas
CREATE TABLE IF NOT EXISTS ingredientes (
  id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL UNIQUE,
  unidad_medida VARCHAR(20) NOT NULL,
  stock_minimo DECIMAL(10,3) NOT NULL DEFAULT 0,
  estado VARCHAR(15) NOT NULL DEFAULT 'Activo',
  CONSTRAINT ck_ingredientes_minimo CHECK (stock_minimo >= 0),
  CONSTRAINT ck_ingredientes_estado
    CHECK (estado IN ('Activo', 'Inactivo'))
) ENGINE=InnoDB;

-- Receta: relación entre productos e ingredientes
CREATE TABLE IF NOT EXISTS producto_ingrediente (
  id_producto INT NOT NULL,
  id_ingrediente INT NOT NULL,
  cantidad_requerida DECIMAL(10,3) NOT NULL,
  PRIMARY KEY (id_producto, id_ingrediente),
  CONSTRAINT ck_receta_cantidad CHECK (cantidad_requerida > 0),
  CONSTRAINT fk_receta_producto
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    ON DELETE CASCADE,
  CONSTRAINT fk_receta_ingrediente
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente)
) ENGINE=InnoDB;

-- Una fila de inventario por ingrediente
CREATE TABLE IF NOT EXISTS inventario (
  ingrediente_id INT PRIMARY KEY,
  cantidad_actual DECIMAL(10,3) NOT NULL DEFAULT 0,
  fecha_actualizacion DATE NOT NULL,
  CONSTRAINT ck_inventario_cantidad CHECK (cantidad_actual >= 0),
  CONSTRAINT fk_inventario_ingrediente
    FOREIGN KEY (ingrediente_id) REFERENCES ingredientes(id_ingrediente)
) ENGINE=InnoDB;

-- Pedidos registrados por los empleados
CREATE TABLE IF NOT EXISTS pedidos (
  id_pedido INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NULL,
  id_empleado INT NOT NULL,
  fecha DATE NOT NULL,
  estado VARCHAR(20) NOT NULL DEFAULT 'Recibido',
  CONSTRAINT ck_pedidos_estado
    CHECK (estado IN ('Recibido', 'En preparación', 'Entregado', 'Cancelado')),
  CONSTRAINT fk_pedidos_cliente
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
    ON DELETE SET NULL,
  CONSTRAINT fk_pedidos_empleado
    FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado)
) ENGINE=InnoDB;

-- Productos y cantidades de cada pedido
CREATE TABLE IF NOT EXISTS detalle_pedido (
  id_detalle INT AUTO_INCREMENT PRIMARY KEY,
  id_pedido INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  CONSTRAINT uq_detalle_pedido_producto
    UNIQUE (id_pedido, id_producto),
  CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_detalle_precio CHECK (precio_unitario >= 0),
  CONSTRAINT fk_detalle_pedido
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
    ON DELETE CASCADE,
  CONSTRAINT fk_detalle_producto
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
) ENGINE=InnoDB;

-- Pagos asociados a los pedidos
CREATE TABLE IF NOT EXISTS pagos (
  id_pago INT AUTO_INCREMENT PRIMARY KEY,
  id_pedido INT NOT NULL,
  fecha_pago DATE NOT NULL,
  metodo_pago VARCHAR(25) NOT NULL,
  monto DECIMAL(10,2) NOT NULL,
  estado VARCHAR(15) NOT NULL DEFAULT 'Registrado',
  CONSTRAINT ck_pagos_monto CHECK (monto > 0),
  CONSTRAINT ck_pagos_estado
    CHECK (estado IN ('Registrado', 'Anulado')),
  CONSTRAINT fk_pagos_pedido
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Datos de prueba: categorías
INSERT IGNORE INTO categorias (id_categoria, nombre, descripcion) VALUES
(1,'Batidos','Batidos de frutas y proteína'),
(2,'Waffles','Waffles saludables'),
(3,'Pancakes','Pancakes y variantes'),
(4,'Bowls de helado','Bowls fríos'),
(5,'Sándwiches','Sándwiches y wraps'),
(6,'Suplementos','Suplementos deportivos'),
(7,'Sodas','Bebidas gasificadas'),
(8,'Bowls de fruta','Fruta, granola y toppings'),
(9,'Combos','Paquetes de productos'),
(10,'Snacks saludables','Porciones y snacks'),
(11,'Café','Café y bebidas con café'),
(12,'Jugos','Jugos naturales'),
(13,'Tés','Tés e infusiones'),
(14,'Postres fitness','Postres saludables'),
(15,'Bebidas especiales','Bebidas de temporada');

-- Datos de prueba: clientes
INSERT IGNORE INTO clientes (id_cliente, nombre, telefono, correo) VALUES
(1,'Juan Pérez','3015550201','juan.perez@example.com'),
(2,'María Gómez','3015550202','maria.gomez@example.com'),
(3,'Carlos Ruiz','3015550203','carlos.ruiz@example.com'),
(4,'Ana Torres','3015550204','ana.torres@example.com'),
(5,'Luis Martínez','3015550205','luis.martinez@example.com'),
(6,'Paula Díaz','3015550206','paula.diaz@example.com'),
(7,'Diego Castro','3015550207','diego.castro@example.com'),
(8,'Sara López','3015550208','sara.lopez@example.com'),
(9,'Miguel Herrera','3015550209','miguel.herrera@example.com'),
(10,'Elena Moreno','3015550210','elena.moreno@example.com'),
(11,'David Rojas','3015550211','david.rojas@example.com'),
(12,'Lucía Vega','3015550212','lucia.vega@example.com'),
(13,'Tomás Gil','3015550213','tomas.gil@example.com'),
(14,'Natalia León','3015550214','natalia.leon@example.com'),
(15,'Andrés Silva','3015550215','andres.silva@example.com');

-- Datos de prueba: empleados.
-- DEMO_NO_VALIDO es un marcador, no un hash de contraseña utilizable.
INSERT IGNORE INTO empleados
(id_empleado, nombre, apellido, telefono, puesto, id_rol, usuario,
 contrasena_hash, estado) VALUES
(1,'Laura','Pérez','3005550101','Administradora',1,'laura.admin','DEMO_NO_VALIDO','Activo'),
(2,'Andrés','Gómez','3005550102','Cajero',2,'andres.gomez','DEMO_NO_VALIDO','Activo'),
(3,'María','Ruiz','3005550103','Cajera',2,'maria.ruiz','DEMO_NO_VALIDO','Activo'),
(4,'Carlos','Díaz','3005550104','Preparador',2,'carlos.diaz','DEMO_NO_VALIDO','Activo'),
(5,'Sofía','Torres','3005550105','Preparadora',2,'sofia.torres','DEMO_NO_VALIDO','Activo'),
(6,'Daniel','Castro','3005550106','Cajero',2,'daniel.castro','DEMO_NO_VALIDO','Activo'),
(7,'Valentina','López','3005550107','Preparadora',2,'valentina.lopez','DEMO_NO_VALIDO','Activo'),
(8,'Mateo','Herrera','3005550108','Preparador',2,'mateo.herrera','DEMO_NO_VALIDO','Activo'),
(9,'Camila','Moreno','3005550109','Cajera',2,'camila.moreno','DEMO_NO_VALIDO','Activo'),
(10,'Samuel','Ortega','3005550110','Cajero',2,'samuel.ortega','DEMO_NO_VALIDO','Activo'),
(11,'Isabella','Ramos','3005550111','Preparadora',2,'isabella.ramos','DEMO_NO_VALIDO','Activo'),
(12,'Nicolás','Vargas','3005550112','Cajero',2,'nicolas.vargas','DEMO_NO_VALIDO','Activo'),
(13,'Gabriela','Mendoza','3005550113','Preparadora',2,'gabriela.mendoza','DEMO_NO_VALIDO','Activo'),
(14,'Julián','Navarro','3005550114','Preparador',2,'julian.navarro','DEMO_NO_VALIDO','Activo'),
(15,'Daniela','Reyes','3005550115','Cajera',2,'daniela.reyes','DEMO_NO_VALIDO','Inactivo');

-- Datos de prueba: productos
INSERT IGNORE INTO productos
(id_producto, id_categoria, nombre, descripcion, precio, estado) VALUES
(1,1,'Batido Verde Detox','Piña, espinaca y banano',18000,'Activo'),
(2,1,'Batido Proteico','Banano y proteína de suero',22000,'Activo'),
(3,2,'Waffle de Avena','Waffle con avena y fruta',20000,'Activo'),
(4,3,'Pancakes de Banano','Pancakes integrales',19000,'Activo'),
(5,4,'Bowl de Açaí','Açaí con fruta y granola',26000,'Activo'),
(6,5,'Sándwich Fitness','Pollo y vegetales',24000,'Activo'),
(7,6,'Proteína Whey','Porción individual',12000,'Activo'),
(8,7,'Soda de Frutos Rojos','Soda artesanal',10000,'Activo'),
(9,8,'Bowl Tropical','Mango, piña y granola',21000,'Activo'),
(10,9,'Combo Energía','Batido y waffle',34000,'Activo'),
(11,10,'Barra de Granola','Barra de avena y miel',7000,'Activo'),
(12,11,'Café Americano','Café negro',6000,'Activo'),
(13,12,'Jugo de Naranja','Jugo natural',9000,'Activo'),
(14,13,'Té de Hierbabuena','Infusión natural',6500,'Activo'),
(15,14,'Brownie Proteico','Brownie de cacao',11000,'Activo');

-- Datos de prueba: ingredientes
INSERT IGNORE INTO ingredientes
(id_ingrediente, nombre, unidad_medida, stock_minimo, estado) VALUES
(1,'Banano','g',1000,'Activo'),
(2,'Piña','g',1000,'Activo'),
(3,'Espinaca','g',300,'Activo'),
(4,'Proteína de suero','g',500,'Activo'),
(5,'Avena','g',1000,'Activo'),
(6,'Huevo','unidad',30,'Activo'),
(7,'Leche','ml',2000,'Activo'),
(8,'Fresa','g',700,'Activo'),
(9,'Granola','g',800,'Activo'),
(10,'Açaí','g',500,'Activo'),
(11,'Pollo','g',1000,'Activo'),
(12,'Pan integral','unidad',20,'Activo'),
(13,'Mango','g',800,'Activo'),
(14,'Naranja','unidad',25,'Activo'),
(15,'Cacao','g',400,'Activo'),
(16,'Café molido','g',300,'Activo'),
(17,'Hierbabuena','g',100,'Activo'),
(18,'Agua','ml',3000,'Activo'),
(19,'Base de soda','ml',1000,'Activo');

-- Ingredientes requeridos por producto
INSERT IGNORE INTO producto_ingrediente
(id_producto, id_ingrediente, cantidad_requerida) VALUES
(1,1,80),(1,2,120),(1,3,30),
(2,1,100),(2,4,30),(2,7,200),
(3,5,100),(3,6,1),(3,7,100),
(4,1,100),(4,5,80),(4,6,2),
(5,10,150),(5,8,60),(5,9,40),
(6,11,120),(6,12,2),
(7,4,30),
(8,8,100),(8,18,200),(8,19,150),
(9,13,100),(9,2,80),(9,7,100),
(10,1,80),(10,5,60),
(11,5,40),(11,9,10),
(12,16,12),(12,18,180),
(13,14,2),
(14,17,8),(14,18,200),
(15,15,35),(15,5,40),(15,6,1);

-- Existencias actuales: una fila por ingrediente
INSERT IGNORE INTO inventario
(ingrediente_id, cantidad_actual, fecha_actualizacion) VALUES
(1,5400,'2026-10-08'),(2,3200,'2026-10-08'),(3,900,'2026-10-08'),
(4,1400,'2026-10-08'),(5,4100,'2026-10-08'),(6,48,'2026-10-08'),
(7,6500,'2026-10-08'),(8,1300,'2026-10-08'),(9,2100,'2026-10-08'),
(10,800,'2026-10-08'),(11,2600,'2026-10-08'),(12,35,'2026-10-08'),
(13,1700,'2026-10-08'),(14,40,'2026-10-08'),(15,750,'2026-10-08'),
(16,600,'2026-10-08'),(17,180,'2026-10-08'),(18,12000,'2026-10-08'),
(19,2500,'2026-10-08');

-- Pedidos
INSERT IGNORE INTO pedidos
(id_pedido, id_cliente, id_empleado, fecha, estado) VALUES
(1,1,2,'2026-10-01','Entregado'),
(2,1,3,'2026-10-01','Entregado'),
(3,1,4,'2026-10-02','Entregado'),
(4,4,5,'2026-10-02','Entregado'),
(5,5,6,'2026-10-03','Entregado'),
(6,6,7,'2026-10-03','Entregado'),
(7,7,8,'2026-10-04','Entregado'),
(8,8,9,'2026-10-04','Entregado'),
(9,9,10,'2026-10-05','Entregado'),
(10,10,11,'2026-10-05','Entregado'),
(11,11,12,'2026-10-06','Entregado'),
(12,12,13,'2026-10-06','Entregado'),
(13,13,14,'2026-10-07','Entregado'),
(14,14,2,'2026-10-07','En preparación'),
(15,15,3,'2026-10-08','Recibido');

-- Líneas de pedido
INSERT IGNORE INTO detalle_pedido
(id_detalle, id_pedido, id_producto, cantidad, precio_unitario) VALUES
(1,1,1,2,18000),(2,1,3,1,20000),
(3,2,2,1,22000),(4,2,5,1,26000),
(5,3,1,1,18000),(6,3,6,1,24000),
(7,4,4,2,19000),(8,4,8,1,10000),
(9,5,5,1,26000),(10,5,7,2,12000),
(11,6,2,2,22000),(12,6,11,2,7000),
(13,7,3,1,20000),(14,7,12,2,6000),
(15,8,1,1,18000),(16,8,9,1,21000),
(17,9,6,1,24000),(18,9,13,1,9000),
(19,10,4,1,19000),(20,10,14,1,6500),
(21,11,2,1,22000),(22,11,15,2,11000),
(23,12,5,2,26000),(24,12,8,1,10000),
(25,13,1,1,18000),(26,13,10,1,34000),
(27,14,3,2,20000),(28,14,7,1,12000),
(29,15,9,1,21000),(30,15,12,1,6000);

-- Pagos asociados a los pedidos
INSERT IGNORE INTO pagos
(id_pago, id_pedido, fecha_pago, metodo_pago, monto, estado) VALUES
(1,1,'2026-10-01','Efectivo',56000,'Registrado'),
(2,2,'2026-10-01','Transferencia',48000,'Registrado'),
(3,3,'2026-10-02','Tarjeta',42000,'Registrado'),
(4,4,'2026-10-02','Efectivo',48000,'Registrado'),
(5,5,'2026-10-03','Transferencia',50000,'Registrado'),
(6,6,'2026-10-03','Tarjeta',58000,'Registrado'),
(7,7,'2026-10-04','Efectivo',32000,'Registrado'),
(8,8,'2026-10-04','Transferencia',39000,'Registrado'),
(9,9,'2026-10-05','Tarjeta',33000,'Registrado'),
(10,10,'2026-10-05','Efectivo',25500,'Registrado'),
(11,11,'2026-10-06','Transferencia',44000,'Registrado'),
(12,12,'2026-10-06','Tarjeta',62000,'Registrado'),
(13,13,'2026-10-07','Efectivo',52000,'Registrado'),
(14,14,'2026-10-07','Transferencia',52000,'Registrado'),
(15,15,'2026-10-08','Tarjeta',27000,'Registrado');

