# Se crea la base de datos y se marca como la base de datos activa 
CREATE DATABASE IF NOT EXISTS estetica;
USE estetica;

# Se especifica cuáles son los nombres de los programas y los puntos requeridos
CREATE TABLE programas(id_programa       INT PRIMARY KEY NOT NULL,
                       nombre            VARCHAR(30) NOT NULL,
                       puntos_requeridos INT NOT NULL);

# Clientes e información básica (id_programa NULL por defecto para evitar fallos de Foreign Key)
# ID programa se entiende como nivel del programa
CREATE TABLE clientes(id_cliente             INT PRIMARY KEY NOT NULL,
                      nombre                 VARCHAR(30) NOT NULL,
                      email                  VARCHAR(30) NOT NULL,
                      telefono               VARCHAR(20) NOT NULL,
                      fecha_nacimiento       DATE,
                      puntos_acumulados_saldo INT NOT NULL DEFAULT 0,
                      id_programa            INT NULL DEFAULT NULL, 
                      nombre_programa        VARCHAR(30) NOT NULL DEFAULT 'Cliente Regular',
                      CONSTRAINT fk_clientes_programa FOREIGN KEY (id_programa) REFERENCES programas(id_programa) );

# Tipos de procedimientos ofertados por la estética
CREATE TABLE procedimientos(id_procedimiento INT PRIMARY KEY NOT NULL,
                            nombre           VARCHAR(100) NOT NULL,
                            categoria        VARCHAR(30) NOT NULL,
                            descripcion      VARCHAR(100) NOT NULL,
                            duracion_min     INT NOT NULL,
                            precio_base      FLOAT NOT NULL);

# Estado actual del inventario
CREATE TABLE inventario(id_producto        INT PRIMARY KEY NOT NULL,
                        venta_general      BOOLEAN NOT NULL,
                        nombre             VARCHAR(50) NOT NULL,
                        proveedor          VARCHAR(50) NOT NULL,
                        telefono_proveedor VARCHAR(30) NOT NULL,
                        precio_compra      FLOAT NOT NULL,
                        precio_base_venta  FLOAT,
                        stock              FLOAT NOT NULL,
                        unidad_medida      VARCHAR(30) NOT NULL);

# Especialistas disponibles para la estética
CREATE TABLE especialistas(id_especialista       INT PRIMARY KEY NOT NULL,
                           nombre                VARCHAR(30) NOT NULL,
                           telefono              VARCHAR(20) NOT NULL,
                           disponibilidad_inicio TIME NOT NULL,
                           disponibilidad_final  TIME NOT NULL);

# Tipo de factura emitida (se añaden valores DEFAULT 0 para permitir carga parcial por CSV)
CREATE TABLE ventas(id_venta          INT PRIMARY KEY NOT NULL,
                    id_cliente        INT NOT NULL,
                    tipo_venta        ENUM('cita','producto','mixta') NOT NULL,
                    fecha_hora        DATETIME,
                    subtotal          FLOAT NOT NULL DEFAULT 0,
                    puntos_acumulados FLOAT NOT NULL DEFAULT 0,
                    puntos_redimidos  FLOAT DEFAULT 0,
                    descuento         FLOAT DEFAULT 0,
                    impuestos         FLOAT NOT NULL DEFAULT 0,
                    total             FLOAT NOT NULL DEFAULT 0,
                    CONSTRAINT fk_ventas_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) );

# Condiciones y alergias de clientes
CREATE TABLE alergia_cond(id_cliente  INT NOT NULL,
                          id_cond     INT NOT NULL,
                          tipo        ENUM('alergia','condicion') NOT NULL,
                          descripcion VARCHAR(50) NOT NULL,
                          PRIMARY KEY (id_cliente, id_cond),
                          CONSTRAINT fk_alergia_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) );

# Certificaciones de especialistas
CREATE TABLE esp_cert(id_hab            INT PRIMARY KEY NOT NULL,
                      id_especialista   INT NOT NULL,
                      nombre            VARCHAR(70) NOT NULL,
                      fecha_emision     DATE,
                      fecha_vencimiento DATE,
                      CONSTRAINT fk_esp_cert_especialista FOREIGN KEY (id_especialista) REFERENCES especialistas(id_especialista) );

# Procedimientos autorizados por especialista
CREATE TABLE esp_proc_autorizado(id_especialista  INT NOT NULL,
                                 id_procedimiento INT NOT NULL,
                                 PRIMARY KEY (id_especialista, id_procedimiento),
                                 CONSTRAINT fk_esp_proc_especialista FOREIGN KEY (id_especialista) REFERENCES especialistas(id_especialista),
                                 CONSTRAINT fk_esp_proc_procedimiento FOREIGN KEY (id_procedimiento) REFERENCES procedimientos(id_procedimiento) );

# Insumos requeridos por procedimiento
CREATE TABLE mat_req_proc(id_procedimiento          INT NOT NULL,
                          id_producto               INT NOT NULL,
                          consumo_unidades_promedio FLOAT NOT NULL,
                          PRIMARY KEY (id_procedimiento, id_producto),
                          CONSTRAINT fk_mat_req_proc_procedimiento FOREIGN KEY (id_procedimiento) REFERENCES procedimientos(id_procedimiento),
                          CONSTRAINT fk_mat_req_proc_inventario FOREIGN KEY (id_producto) REFERENCES inventario(id_producto) );

# Citas programadas
CREATE TABLE citas(id_cita          INT PRIMARY KEY NOT NULL,
                   id_cliente       INT NOT NULL,
                   id_especialista  INT NOT NULL,
                   id_procedimiento INT NOT NULL,
                   fecha            DATE NOT NULL,
                   hora             TIME NOT NULL,
                   estado           ENUM('programada', 'completada', 'cancelada') NOT NULL DEFAULT 'programada',
                   CONSTRAINT id_cliente_fk1 FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
                   CONSTRAINT id_especialista_fk1 FOREIGN KEY (id_especialista) REFERENCES especialistas(id_especialista),
                   CONSTRAINT id_procedimiento_fk2 FOREIGN KEY (id_procedimiento) REFERENCES procedimientos(id_procedimiento),
                   CONSTRAINT chk_rango_horario CHECK (hora >= '08:00:00' AND hora <= '18:00:00') );

# Movimientos de inventario
CREATE TABLE mov_inventario(id_movimiento INT PRIMARY KEY NOT NULL,
                            id_producto   INT NOT NULL,
                            movimiento    BOOLEAN NOT NULL, -- 0 out, 1 in 
                            cita_venta    BOOLEAN NOT NULL, -- 0 cita, 1 venta 
                            fecha_hora    DATETIME,
                            descripcion   VARCHAR(50),
                            cantidad      FLOAT NOT NULL,
                            CONSTRAINT fk_mov_inventario_producto FOREIGN KEY (id_producto) REFERENCES inventario(id_producto) );

# Consumo de inventario por cita
CREATE TABLE cita_mov_inventario(id_movimiento INT NOT NULL,
                                 id_cita       INT NOT NULL,
                                 PRIMARY KEY (id_movimiento, id_cita),
                                 CONSTRAINT fk_cmi_movimiento FOREIGN KEY (id_movimiento) REFERENCES mov_inventario(id_movimiento),
                                 CONSTRAINT fk_cmi_cita FOREIGN KEY (id_cita) REFERENCES citas(id_cita) );

# Consumo de inventario por venta
CREATE TABLE venta_mov_inventario(id_movimiento INT NOT NULL,
                                  id_venta      INT NOT NULL,
                                  PRIMARY KEY (id_movimiento, id_venta),
                                  CONSTRAINT fk_vmi_movimiento FOREIGN KEY (id_movimiento) REFERENCES mov_inventario(id_movimiento),
                                  CONSTRAINT fk_vmi_venta FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) );

# Citas incluidas en ventas
CREATE TABLE cita_venta(id_venta INT NOT NULL,
                        id_cita  INT NOT NULL,
                        subtotal FLOAT NOT NULL,
                        PRIMARY KEY (id_venta, id_cita),
                        CONSTRAINT fk_cita_venta_venta FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
                        CONSTRAINT fk_cita_venta_cita FOREIGN KEY (id_cita) REFERENCES citas(id_cita) );

# Productos incluidos en ventas
CREATE TABLE producto_venta(id_venta    INT NOT NULL,
                            id_producto INT NOT NULL,
                            cantidad    INT NOT NULL,
                            subtotal    FLOAT NOT NULL,
                            PRIMARY KEY (id_venta, id_producto),
                            CONSTRAINT fk_pv_venta FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
                            CONSTRAINT fk_pv_producto FOREIGN KEY (id_producto) REFERENCES inventario(id_producto) );

# Registro de visitas -- el cliente se registra en el counter al entrar a la estetica y deja registro de la visita
CREATE TABLE visita(reg_visita INT PRIMARY KEY NOT NULL,
                    id_cliente INT NOT NULL,
                    fecha      DATE NOT NULL,
                    hora       TIME NOT NULL,
                    cita       BOOLEAN NOT NULL, -- el cliente asisito a una cita
                    compra     BOOLEAN NOT NULL, -- el cliente hizo una compra
                    CONSTRAINT fk_visita_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) );



# ---------------------------------------------------------
# CARGA MASIVA DE DATOS
# ---------------------------------------------------------

SET foreign_key_checks = 0;

# 1. Tablas Primarias (Padres)
LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/programas.csv' 
INTO TABLE programas 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/clientes.csv' INTO TABLE clientes FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES (id_cliente, nombre, email, telefono, fecha_nacimiento);

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/especialistas.csv' INTO TABLE especialistas FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/procedimientos.csv' INTO TABLE procedimientos FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/inventario.csv' INTO TABLE inventario FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES (id_producto, venta_general, nombre, proveedor, telefono_proveedor, precio_compra, @vprecio_base_venta, stock, unidad_medida) SET precio_base_venta = nullif(TRIM(@vprecio_base_venta), '');

# 2. Tablas Transaccionales
LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/citas.csv' INTO TABLE citas FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/ventas.csv' INTO TABLE ventas FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES (id_venta, id_cliente, tipo_venta, fecha_hora, @vpuntos_redimidos) SET puntos_redimidos = nullif(TRIM(@vpuntos_redimidos), '');

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/mov_inventario.csv' INTO TABLE mov_inventario FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

# 3. Tablas Relacionales e Intermedias
LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/alergia_cond.csv' INTO TABLE alergia_cond FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/esp_cert.csv' INTO TABLE esp_cert FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES (id_hab, id_especialista, nombre, @fecha_emision, @fecha_vencimiento) SET fecha_emision = nullif(@fecha_emision, ''), fecha_vencimiento = nullif(@fecha_vencimiento, '');

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/esp_proc_autorizado.csv' INTO TABLE esp_proc_autorizado FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/mat_req_proc.csv' INTO TABLE mat_req_proc FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/cita_venta.csv' INTO TABLE cita_venta FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/producto_venta.csv' INTO TABLE producto_venta FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/cita_mov_inventario.csv' INTO TABLE cita_mov_inventario FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/venta_mov_inventario.csv' INTO TABLE venta_mov_inventario FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA INFILE 'D:/ProgramData/MySQL/MySQL Server 9.0/Uploads/visita.csv' INTO TABLE visita FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

SET foreign_key_checks = 1;

UPDATE ventas v
SET    v.subtotal = CASE
                      WHEN v.tipo_venta = 'cita' THEN
                        Coalesce((SELECT Sum(cv.subtotal) FROM cita_venta cv WHERE cv.id_venta = v.id_venta), 0)
                      WHEN v.tipo_venta = 'producto' THEN
                        Coalesce((SELECT Sum(pv.subtotal) FROM producto_venta pv WHERE pv.id_venta = v.id_venta), 0)
                      WHEN v.tipo_venta = 'mixta' THEN
                        Coalesce((SELECT Sum(cv.subtotal) FROM cita_venta cv WHERE cv.id_venta = v.id_venta), 0)
                        + Coalesce((SELECT Sum(pv.subtotal) FROM producto_venta pv WHERE pv.id_venta = v.id_venta), 0)
                      ELSE 0
                    END
WHERE  v.id_venta >= 1;

# Paso 2: impuestos, descuento, total y puntos a partir del subtotal
UPDATE ventas v
SET    v.impuestos = v.subtotal * 0.19,
       v.descuento = (Coalesce(v.puntos_redimidos, 0) * 100),
       v.total = (v.subtotal - (Coalesce(v.puntos_redimidos, 0) * 100)) + (v.subtotal * 0.19),
       v.puntos_acumulados = Floor(v.subtotal / 1000)
WHERE  v.id_venta >= 1;

# Nombre del programa de puntos
# El saldo es lo acumulado menos lo redimido; el nivel del programa se basa en lo acumulado
UPDATE clientes c
LEFT JOIN ( SELECT id_cliente,
                   Coalesce(Sum(puntos_acumulados), 0)      AS total_acumulado,
                   Coalesce(Sum(puntos_redimidos), 0)       AS total_redimido
            FROM   ventas
            GROUP  BY id_cliente ) v
       ON c.id_cliente = v.id_cliente
SET    c.puntos_acumulados_saldo = Coalesce(v.total_acumulado, 0) - Coalesce(v.total_redimido, 0),
       c.id_programa = (SELECT   p.id_programa
                        FROM     programas p
                        WHERE    Coalesce(v.total_acumulado,
                                          0) >= p.puntos_requeridos
                        ORDER BY p.puntos_requeridos DESC LIMIT 1),
       c.nombre_programa = Coalesce( ( SELECT p.nombre FROM programas p WHERE Coalesce(v.total_acumulado, 0) >= p.puntos_requeridos ORDER BY p.puntos_requeridos DESC LIMIT 1 ), 'Cliente Regular' )
WHERE  c.id_cliente > 0;



# ---------------------------------------------------------
# TRIGGERS (se crean después de la carga masiva)
# ---------------------------------------------------------
DELIMITER //

# Validar si stock es negativo y actualizar stock
# NOTA: se ejecuta al INSERTAR un movimiento. Las tablas cita_mov_inventario y
# venta_mov_inventario se llenan aparte (el trigger no conoce id_cita ni id_venta).
DROP TRIGGER IF EXISTS update_stock_trigger//
CREATE TRIGGER update_stock_trigger
AFTER INSERT ON mov_inventario
FOR EACH ROW
BEGIN
  DECLARE current_stock FLOAT;

  IF NEW.movimiento THEN
    UPDATE inventario SET stock = stock + NEW.cantidad WHERE id_producto = NEW.id_producto;
  ELSE
    UPDATE inventario SET stock = stock - NEW.cantidad WHERE id_producto = NEW.id_producto;
    
    SELECT stock INTO current_stock FROM inventario WHERE id_producto = NEW.id_producto;
    
    IF current_stock < 0 THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El stock no puede ser negativo';
    END IF;
  END IF;
END//

# Validar si producto es de venta general
DROP TRIGGER IF EXISTS validar_venta_producto_insert//
CREATE TRIGGER validar_venta_producto_insert BEFORE INSERT ON producto_venta FOR EACH ROW
  BEGIN
    DECLARE v_venta_general BOOLEAN;
    SELECT venta_general
    INTO   v_venta_general
    FROM   inventario
    WHERE  id_producto = new.id_producto;
    IF v_venta_general = false OR v_venta_general IS NULL THEN
      SIGNAL SQLSTATE '45000' SET message_text = 'Este producto es de uso profesional interno y no está disponible para venta directa.';
    END IF;
  END //

# Validar disp especialista
# Revisa que la cita COMPLETA (inicio y fin) quede dentro del horario del especialista
# y que el especialista esté autorizado para el procedimiento
DROP TRIGGER IF EXISTS disponibilidad_inicio_insert//
CREATE TRIGGER disponibilidad_inicio_insert BEFORE INSERT ON citas FOR EACH ROW
  BEGIN
    DECLARE v_disponibilidad_inicio TIME;
    DECLARE v_disponibilidad_final TIME;
    DECLARE v_duracion INT;

    SELECT disponibilidad_inicio,
           disponibilidad_final
    INTO   v_disponibilidad_inicio, v_disponibilidad_final
    FROM   especialistas
    WHERE  id_especialista = new.id_especialista;

    SELECT duracion_min
    INTO   v_duracion
    FROM   procedimientos
    WHERE  id_procedimiento = new.id_procedimiento;

    IF v_duracion IS NULL THEN
      SIGNAL SQLSTATE '45000' SET message_text = 'El procedimiento no existe';
    END IF;

    IF new.hora < v_disponibilidad_inicio
       OR ADDTIME(new.hora, SEC_TO_TIME(v_duracion * 60)) > v_disponibilidad_final THEN
      SIGNAL SQLSTATE '45000' SET message_text = 'La hora seleccionada está fuera del horario del especialista';
    END IF;

    IF NOT EXISTS (SELECT 1
                   FROM   esp_proc_autorizado
                   WHERE  id_especialista = new.id_especialista
                          AND id_procedimiento = new.id_procedimiento) THEN
      SIGNAL SQLSTATE '45000' SET message_text = 'El especialista no está autorizado para este procedimiento';
    END IF;
  END //

#Validar que ni el cliente ni el especialista se encuentren ocupados
DROP TRIGGER IF EXISTS check_time_slot//
CREATE TRIGGER check_time_slot
BEFORE INSERT ON citas
FOR EACH ROW
BEGIN
  DECLARE v_duracion INT;
  DECLARE v_fin TIME;
  DECLARE v_traslapes_esp INT DEFAULT 0;
  DECLARE v_traslapes_cli INT DEFAULT 0;

  -- Una cita cancelada no ocupa horario
  IF NEW.estado <> 'cancelada' THEN

    SELECT duracion_min INTO v_duracion
    FROM procedimientos
    WHERE id_procedimiento = NEW.id_procedimiento;

    IF v_duracion IS NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El procedimiento no existe';
    END IF;

    SET v_fin = ADDTIME(NEW.hora, SEC_TO_TIME(v_duracion * 60));

    SELECT COALESCE(SUM(c.id_especialista = NEW.id_especialista), 0),
           COALESCE(SUM(c.id_cliente = NEW.id_cliente), 0)
    INTO   v_traslapes_esp, v_traslapes_cli
    FROM citas c
    JOIN procedimientos p ON p.id_procedimiento = c.id_procedimiento
    WHERE c.fecha = NEW.fecha
      AND c.estado <> 'cancelada'
      AND (c.id_especialista = NEW.id_especialista OR c.id_cliente = NEW.id_cliente)
      AND NEW.hora < ADDTIME(c.hora, SEC_TO_TIME(p.duracion_min * 60))
      AND v_fin > c.hora;

    IF v_traslapes_esp > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El horario se traslapa con otra cita del especialista';
    END IF;

    IF v_traslapes_cli > 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente ya tiene otra cita en ese horario';
    END IF;

  END IF;
END//

#Validar que saldo puntos o que no se usen mas de los necesarios
DROP TRIGGER IF EXISTS update_points_before_insert//
CREATE TRIGGER update_points_before_insert
BEFORE INSERT ON ventas
FOR EACH ROW
BEGIN
  DECLARE v_saldo INT;

  SET NEW.puntos_redimidos = COALESCE(NEW.puntos_redimidos, 0);
  SET NEW.puntos_acumulados = FLOOR(NEW.subtotal / 1000);

  IF NEW.puntos_redimidos * 100 > NEW.subtotal THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Los puntos redimidos exceden el subtotal';
  END IF;

  SELECT puntos_acumulados_saldo INTO v_saldo
  FROM clientes
  WHERE id_cliente = NEW.id_cliente
  FOR UPDATE;

  IF NEW.puntos_redimidos > v_saldo THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El cliente no cuenta con puntos suficientes';
  END IF;

  UPDATE clientes
  SET puntos_acumulados_saldo = puntos_acumulados_saldo
      + NEW.puntos_acumulados - NEW.puntos_redimidos
  WHERE id_cliente = NEW.id_cliente;
END//

DELIMITER ;
