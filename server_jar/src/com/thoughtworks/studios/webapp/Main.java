package com.thoughtworks.studios.webapp;

import java.io.File;
import java.io.StringReader;
import java.net.URL;
import java.util.Properties;

/**
 * Example:
 * java [JVMARGS] [-Dkey=value] -jar ccrb.war
 * ccrb.war is loaded on http://localhost:8080/
 *
 * See ccrb.properties for supported keys. Some hidden properties can be seen in jetty.xml.
 */

public class Main{
  private static final String MAIN = "/" + Main.class.getName().replace('.', '/') + ".class";
  private static final URL MAIN_CLASS = Main.class.getResource(MAIN);
  private static final String LOG_LEVEL = System.getProperty("ccrb.log.level", "info");

  private File ccrbDataDir;
  private File ccrbWorkDir;
  private File configDir;
  private File logDir;

  private void initialize() throws Exception {
    this.ccrbDataDir = new File(System.getProperty("ccrb.data.dir", ".")).getCanonicalFile();
    this.ccrbDataDir.mkdirs();

    this.configDir = new File(System.getProperty("ccrb.config.dir", new File(this.ccrbDataDir, "config").toString())).getCanonicalFile();
    this.configDir.mkdirs();
    
    this.ccrbWorkDir = new File(this.ccrbDataDir, "work");
    FileUtils.delete(this.ccrbWorkDir);
    this.ccrbWorkDir.mkdirs();
    
    this.logDir = new File(System.getProperty("ccrb.log.dir", new File(this.ccrbDataDir, "log").toString())).getCanonicalFile();
    this.logDir.mkdirs();

    copyConfigFilesFromJar("log4j.properties", "ccrb.properties");
    
    setDefaultProperties();
    loadLuauProperties();

    Runtime.getRuntime().addShutdownHook(new Thread(){
      public void run() {
        FileUtils.delete(Main.this.ccrbWorkDir);
      }
    });
  }

  // setup various properties
  private void loadLuauProperties() throws Exception {
    Properties properties = new Properties();
    String file = FileUtils.read(new File(this.configDir, "ccrb.properties"));
    properties.load(new StringReader(file));
    debug("Setting system properties:" + properties);

    for (String key : properties.stringPropertyNames()) {
      System.setProperty(key, properties.getProperty(key));
    }
  }

  private void setDefaultProperties() throws Exception {
    setJettySystemProperties();
    setLuauSystemProperties();
    setLoggingProperties();
  }

  public void setLoggingProperties() {
    if (System.getProperty("log4j.configuration") == null) {
      System.setProperty("log4j.configuration", new File(this.configDir, "log4j.properties").toURI().toString());
    }

    String configFile = System.getProperty("log4j.configuration").replace("file://", "");
    if (configFile.endsWith(".xml")){
      org.apache.log4j.xml.DOMConfigurator.configureAndWatch(configFile, 5000);
    } else {
      org.apache.log4j.PropertyConfigurator.configureAndWatch(configFile, 5000);
    }
  }

  private void setLuauSystemProperties() throws Exception {
    System.setProperty("ccrb.log.dir", this.logDir.toString()); // used by ccrb in log4j.properties
    // these are used by ccrb in constants.rb
    System.setProperty("ccrb.data.dir", this.ccrbDataDir.getCanonicalPath());
    System.setProperty("ccrb.config.dir", this.configDir.getCanonicalPath());
    System.setProperty("ccrb.log.level", LOG_LEVEL);
  }
  
  private void setJettySystemProperties() throws Exception {
    System.setProperty("ccrb.jetty.workdir", this.ccrbWorkDir.toString());
    System.setProperty("ccrb.jetty.war.location", ccrbPath());
    System.setProperty("ccrb.jetty.web.xml", webXmlPath());
  }

  private void copyConfigFilesFromJar(String... files){
    for(String file: files){
      File targetFile = new File(this.configDir, file);
      if (!targetFile.exists()){
        FileUtils.write(targetFile, FileUtils.read(getClass().getResourceAsStream("/ccrb-config/" + file)));
      }
    }
  }
  
  private void start() throws Exception {
    org.mortbay.start.Main.main(new String[]{jettyXmlPath()});
  }

  // paths to various paths, with system properties overriding everything else.
  private String jettyXmlPath() throws Exception {
    String path = MAIN_CLASS.toURI().getSchemeSpecificPart();
    String defaultJettyXml = new URL("jar:" + path.replace(MAIN, "/jetty.home/etc/jetty.xml")).toString();
    return System.getProperty("ccrb.jetty.xml.config", defaultJettyXml);
  }

  private String webXmlPath() throws Exception {
    return System.getProperty("ccrb.jetty.web.xml", ccrbPath() + "/WEB-INF/web.xml");
  }

  private String ccrbPath() throws Exception {
    String path = MAIN_CLASS.toURI().getSchemeSpecificPart();
    // DONT FORGET THE TRAILING SLASH AT THE END OF THE /webapp/
    String defaultWebappPath = new URL("jar:" + path.replace(MAIN, "/webapp/")).toString();
    return System.getProperty("ccrb.jetty.war.location", defaultWebappPath);
  }

  public static void main(String[] args) {
    try {
      Main main = new Main();
      main.initialize();
      main.start();
    } catch (Exception e) {
      System.err.println("error: " + e.toString());
      e.printStackTrace();
      System.exit(1);
    }
  }

  private void debug(String msg) {
    if ("debug".equalsIgnoreCase(LOG_LEVEL)) {
      System.out.println(msg);
    }
  }

}