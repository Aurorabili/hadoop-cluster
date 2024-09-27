package org.example;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

public class Main {
    public static void main(String[] args) {
        Configuration conf = new Configuration();
        conf.set("fs.defaultFS","hdfs://namenode:9000");
        try{
            FileSystem fs = FileSystem.get(conf);
            FSDataOutputStream os = fs.create(new Path("/user/hadoop/hello"));
            os.writeUTF("Hello Hadoop.\nCreated by Java Client.");
            os.close();

            for (FileStatus file : fs.listStatus(new Path("/user/hadoop"))){
                System.out.println(file.getPath().toString());
            }

            fs.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}