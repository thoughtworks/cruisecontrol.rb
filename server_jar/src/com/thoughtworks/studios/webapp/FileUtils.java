package com.thoughtworks.studios.webapp;

import java.io.*;
import java.net.*;
import java.nio.charset.*;
import java.util.List;

public class FileUtils {

  public static String read(File file) {
    try {
      return read(new FileInputStream(file));
    } catch (FileNotFoundException e) {
      throw new RuntimeException(e);
    }
  }

  public static String read(InputStream in) {
    return read(new InputStreamReader(in, Charset.forName("UTF-8")));
  }

  public static String read(URL url) {
    try {
      return read(url.openStream());
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  public static String read(Reader in) {
    StringBuffer buffer = new StringBuffer();
    try {
      while (in.ready()) {
        buffer.append((char) in.read());
      }
    } catch (IOException e) {
      throw new RuntimeException(e);
    } finally {
      close(in);
    }
    return buffer.toString();
  }

  public static void writeLines(File file, String... lines) {
    StringBuffer contents = new StringBuffer();
    for (String line : lines) {
      contents.append(line).append("\n");
    }
    write(file, contents.toString());
  }

  public static void write(File file, String text) {
    BufferedWriter w = null;
    try {
      try {
        w = new BufferedWriter(new FileWriter(file));
        w.append(text);
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    } finally {
      close(w);
    }
  }

  public static void close(Closeable c) {
    if (c != null) {
      try {
        c.close();
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    }
  }
  
  public static void delete(File f) {
    if (f.isDirectory()) {
      File[] children = f.listFiles();
      for (int i = 0; i < children.length; i++) {
        delete(children[i]);
      }
    }
    f.delete();
  }
}