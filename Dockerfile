# Usamos una imagen oficial de Tomcat 10.1 con Java 21
FROM tomcat:10.1-jdk21

# Borramos la app por defecto de Tomcat
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copiamos tu archivo .war compilado a la carpeta webapps de Tomcat
COPY dist/proyecto_textil.war /usr/local/tomcat/webapps/ROOT.war

# Exponemos el puerto
EXPOSE 8080

# Comando para iniciar Tomcat
CMD ["catalina.sh", "run"]