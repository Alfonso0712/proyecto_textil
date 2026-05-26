package modelo;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
public class ConexionDB {

    // URL actualizada para TiDB Cloud (Puerto 4000 y TLS habilitado)
    private static final String URL = "jdbc:mysql://gateway01.us-east-1.prod.aws.tidbcloud.com:4000/textil_db"
            + "?sslMode=VERIFY_IDENTITY"
            + "&enabledTLSProtocols=TLSv1.2,TLSv1.3"
            + "&serverTimezone=UTC";
    
    private static final String USUARIO = "3UZw7TyCfNxAm3m.root";
    private static final String CLAVE = "t6L48H3nV0eplHzP"; // <--- Pega aquí la que generaste

    private ConexionDB() {}

    public static Connection obtenerConexion() throws SQLException {
        try {
            // Asegúrate de tener el driver mysql-connector-j en tus librerías
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(URL, USUARIO, CLAVE);
        } catch (ClassNotFoundException e) {
            throw new SQLException("Driver MySQL no encontrado. Verifica mysql-connector-j", e);
        } catch (SQLException e) {
            System.err.println("Error detallado: " + e.getMessage());
            throw e;
        }
    }
}