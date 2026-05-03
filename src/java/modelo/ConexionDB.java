package modelo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Singleton de conexión a MySQL.
 * Coloca este archivo en: modelo/ConexionDB.java
 */
public class ConexionDB {

    private static final String URL    = "jdbc:mysql://avnadmin:AVNS_7HDn1mf6DN66-Am2Fh-@mysql-20b5e879-gabriellozano176-4915.l.aivencloud.com:13428/defaultdb?ssl-mode=REQUIRED";
    private static final String USUARIO = "avnadmin";       // Cambia por tu usuario MySQL
    private static final String CLAVE   = "AVNS_7HDn1mf6DN66-Am2Fh-";   // Cambia por tu contraseña MySQL

    private ConexionDB() {}

    public static Connection obtenerConexion() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver MySQL no encontrado. Verifica mysql-connector-j en WEB-INF/lib", e);
        }
        return DriverManager.getConnection(URL, USUARIO, CLAVE);
    }
}
