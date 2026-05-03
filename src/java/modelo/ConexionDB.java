package modelo;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Singleton de conexión a MySQL en Aiven.
 */
public class ConexionDB {

    // URL corregida al formato JDBC para Java
    private static final String URL = "jdbc:mysql://mysql-20b5e879-gabriellozano176-4915.l.aivencloud.com:13428/defaultdb?sslMode=REQUIRED";
    private static final String USUARIO = "avnadmin";
    private static final String CLAVE = "AVNS_7HDn1mf6DN66-Am2Fh-";

    private ConexionDB() {}

    public static Connection obtenerConexion() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(URL, USUARIO, CLAVE);
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver MySQL no encontrado. Verifica mysql-connector-j", e);
        }
    }
}
