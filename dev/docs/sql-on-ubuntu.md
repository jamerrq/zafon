# configuración de mysql server en ubuntu (24.04)

## instalación de mysql server

```bash
sudo apt update
sudo apt install mysql-server
```

verifica que el servicio esté corriendo:

```bash
sudo systemctl status mysql
```

## acceso al servidor mysql

por defecto, mysql crea un usuario root que solo se puede usar con `sudo`:

```bash
sudo mysql
```

si necesitas acceder como root sin sudo (por ejemplo, desde python), 
puedes crear un nuevo usuario y darle permisos:

```sql
CREATE USER 'sa'@'localhost' IDENTIFIED BY 'tu_password';
GRANT ALL PRIVILEGES ON *.* TO 'sa'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

## configuración de python para conectar

instala el conector:

```bash
pip install mysql-connector-python
```

ejemplo de conexión:

```python
import mysql.connector

conn = mysql.connector.connect(
    host='localhost',
    user='sa',
    password='tu_password',
    database='database_name'
)
cursor = conn.cursor()
```

## creación de base de datos desde python

si quieres crear la base desde un script:

```python
conn = mysql.connector.connect(
    host='localhost',
    user='sa',
    password='tu_password'
)
cursor = conn.cursor()
cursor.execute("CREATE DATABASE IF NOT EXISTS database_name")
cursor.close()
conn.close()
```

## creación de tablas desde python

una vez creada la base:

```python
conn = mysql.connector.connect(
    host='localhost',
    user='sa',
    password='tu_password',
    database='database_name'
)
cursor = conn.cursor()

cursor.execute('''
CREATE TABLE IF NOT EXISTS table_name (
    id INT PRIMARY KEY,
    column_name column_type
);
''')

conn.commit()
cursor.close()
conn.close()
```

## errores comunes

* `Unknown database 'database_name'`: asegúrate de crear la base antes de conectar.
* `Commands out of sync`: evita ejecutar múltiples queries sobre la misma conexión/cursor sin cerrarlos.
* permisos denegados: verifica los privilegios del usuario con el que te conectas.

## notas adicionales

* puedes listar bases con `SHOW DATABASES;`
* puedes listar tablas con `SHOW TABLES;`
* puedes ver estructura con `DESCRIBE nombre_tabla;`

---

esto permite simular una base en local con las mismas estructuras de producción, sin depender del mismo motor exacto si producción usa sql server o similar.

recomendación: mantener los scripts SQL en archivos `.sql` para facilitar su mantenimiento y ejecución desde línea de comandos si es necesario.
