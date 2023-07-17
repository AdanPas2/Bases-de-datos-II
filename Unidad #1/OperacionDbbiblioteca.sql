/* Usar la base de datos a la cual queremos hacerle las operaciones */

USE DBBiblioteca_Adan_Camacho;


/* insertar una reserva para el usuario Carlos con cédula 8888 de la dependencia
judicial para el material libro el buen vendedor con un valor de 30000, año
2013 y cantidad 1. Sí el usuario y el material no están en la base de datos
también los debe insertar y asumir los datos faltantes.*/

-- Verificar si el usuario ya existe
IF NOT EXISTS (SELECT * FROM tblusuario WHERE Cedula = 8888)
BEGIN
    -- Insertar nuevo usuario
    INSERT INTO tblusuario (Cedula, Nombre, telefono, Direccion, Cod_Tipo, Estado_usuario)
    VALUES (8888, 'Carlos', 0, '', 1, 'Vigente')
END

-- Verificar si la dependencia ya existe
IF NOT EXISTS (SELECT * FROM tbldependencia WHERE Nombre_Dependencia = 'Judicial')
BEGIN
    -- Insertar nueva dependencia
    INSERT INTO tbldependencia (Nombre_Dependencia, Ubicacion)
    VALUES ('Judicial', '')
END

-- Verificar si el material ya existe
IF NOT EXISTS (SELECT * FROM tblMaterial WHERE Nombre_material = 'El buen vendedor')
BEGIN
    -- Insertar nuevo material
    INSERT INTO tblMaterial (Nombre_material, Valor, año, CodTipo_Material, cantidad)
    VALUES ('El buen vendedor', 30000, 2013, 1, 1)
END

-- Insertar reserva
INSERT INTO tblReserva (Fecha, Cedula, Cod_Material)
VALUES (GETDATE(), 8888, (SELECT Cod_material FROM tblMaterial WHERE Nombre_material = 'El buen vendedor'))

-- Mostrar las reservas actualizadas
SELECT * FROM tblReserva



/* Insertar en una tabla llamada TBL_datos los registros de los usuarios con
préstamos vigentes */

-- Crear tabla TBL_datos si no existe
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TBL_datos')
BEGIN
    CREATE TABLE TBL_datos (
        Cedula INT,
        Nombre VARCHAR(30),
        telefono INT,
        Direccion VARCHAR(30),
        Cod_Tipo INT,
        Estado_usuario VARCHAR(30)
    )
END

INSERT INTO TBL_datos (Cedula, Nombre, telefono, Direccion, Cod_Tipo, Estado_usuario)
SELECT
    u.Cedula,
    u.Nombre,
    u.telefono,
    u.Direccion,
    u.Cod_Tipo,
    u.Estado_usuario
FROM
    tblusuario u
JOIN
    tblPrestamo p ON u.Cedula = p.Cedula
WHERE
    p.Fecha_Devolucion <= GETDATE()

SELECT * FROM TBL_datos

/* mostrar los datos de los materiales que no han devuelto los usuarios de
sistemas o de administración */

SELECT
    m.Cod_material,
    m.Nombre_material,
    m.Valor,
    m.año,
    m.CodTipo_Material
FROM
    tblMaterial m
WHERE
    NOT EXISTS (
        SELECT 1
        FROM tblPrestamo p
        INNER JOIN tblusuario u ON p.Cedula = u.Cedula
        INNER JOIN tblTipo_Usuario tu ON u.Cod_Tipo = tu.Cod_tipo
        WHERE m.Cod_material = p.Cod_Material
        AND tu.Nom_Tipo IN ('Sistemas', 'Administración')
        AND p.Num_Ejemplar IS NOT NULL
    )

/* Mostrar los nombres de los materiales y su cantidad de préstamos solo si esta
cantidad es mayor que el promedio de todas las cantidades de los materiales */

SELECT m.Nombre_material, COUNT(p.Cod_Prestamo) AS Cantidad_Prestamos
FROM tblMaterial m
LEFT JOIN tblEjemplar e ON m.Cod_material = e.Cod_Material
LEFT JOIN tblPrestamo p ON e.Num_Ejemplar = p.Num_Ejemplar AND e.Cod_Material = p.Cod_Material
GROUP BY m.Nombre_material
HAVING COUNT(p.Cod_Prestamo) > (
  SELECT AVG(PrestamosPorMaterial.Cantidad_Prestamos)
  FROM (
    SELECT COUNT(p2.Cod_Prestamo) AS Cantidad_Prestamos
    FROM tblMaterial m2
    LEFT JOIN tblEjemplar e2 ON m2.Cod_material = e2.Cod_Material
    LEFT JOIN tblPrestamo p2 ON e2.Num_Ejemplar = p2.Num_Ejemplar AND e2.Cod_Material = p2.Cod_Material
    GROUP BY m2.Cod_material
  ) PrestamosPorMaterial
)


/* Mostrar los datos de los usuarios con estado Betado que pertenecen a todas
las dependencias */

SELECT a.Cedula, a.Nombre, a.telefono, a.Direccion, a.Estado_usuario,
d.Nom_Tipo, Nombre_Dependencia FROM tblusuario as a
FULL OUTER JOIN tblPertenece as b
ON b.Cedula = a.Cedula
FULL OUTER JOIN tbldependencia as c
ON c.Cod_Dependencia = b.Cod_Dependencia
FULL OUTER JOIN tblTipo_Usuario as d
ON d.Cod_tipo = a.Cod_Tipo
WHERE Estado_usuario = 'Betado';

/* Actualizar el estado de los ejemplares de los materiales tipo película o juegos
para estado reservado */

UPDATE tblEjemplar
SET tblEjemplar.estado = 'Reservado'
FROM tblEjemplar as a
INNER JOIN tblMaterial as b
ON b.Cod_material = a.Cod_Material
INNER JOIN tblTipo_Material as c
ON c.CodTipo_Material = b.Cod_material 
WHERE c.NombreTipo_Material IN ('Pelicula', 'Juegos')


/* Actualizar el valor de los materiales en una disminución del 5% con año menor
que 2000 hoy y se han prestado más de 5 veces */

UPDATE tblMaterial
SET Valor = Valor * 0.95
WHERE año < 2000
AND Cod_material IN (
    SELECT Cod_Material
    FROM tblPrestamo
    GROUP BY Cod_Material
    HAVING COUNT(*) > 5
);

/* actualizar el estado de los usuarios Carlos Camilo y Camila a vigente si
pertenecen a las dependencias Judicial */

UPDATE tblusuario
SET Estado_usuario = 'Vigente'
FROM tblusuario as a
INNER JOIN tblPertenece as b
ON b.Cedula = a.Cedula
INNER JOIN tbldependencia as c
ON c.Cod_Dependencia = b.Cod_Dependencia
WHERE a.Nombre IN ('Carlos', 'Camilo', 'Camila') AND
c.Nombre_Dependencia = 'Judicial';


SELECT * FROM tblusuario
SELECT * FROM tblPertenece
select * from tbldependencia



/* Borrar las reservas de los usuarios Carlos Camilo y Camila */

DELETE FROM tblReserva
WHERE Cedula IN (
    SELECT Cedula
    FROM tblusuario
    WHERE Nombre IN ('Carlos', 'Camilo', 'Camila')
);

/* Borrar los préstamos de los ejemplares de los materiales libros */

DELETE FROM tblPrestamo
WHERE Cod_Material IN (
    SELECT Cod_material
    FROM tblMaterial
    WHERE CodTipo_Material = (
        SELECT CodTipo_Material
        FROM tblTipo_Material
        WHERE NombreTipo_Material = 'Libro'
    )
);



