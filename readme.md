# LevelDB JNI

## Description

This fork of LevelDB JNI gives you a Java interface to the 
[PebblesDB](https://github.com/utsaslab/pebblesdb) C++ library, which is
a write-optimized key-value store built with FLSM (Fragmented Log-Structured Merge Tree) data structure. FLSM is a modification of the standard log-structured merge tree data structure which aims at achieving higher write throughput and lower write amplification without compromising on read throughput. 

## API Usage:

Recommended Package imports:

    import org.iq80.leveldb.*;
    import static org.fusesource.leveldbjni.JniDBFactory.*;
    import java.io.*;

Opening and closing the database.

    Options options = new Options();
    options.createIfMissing(true);
    DB db = factory.open(new File("example"), options);
    try {
      // Use the db in here....
    } finally {
      // Make sure you close the db to shutdown the 
      // database and avoid resource leaks.
      db.close();
    }

Putting, Getting, and Deleting key/values.

    db.put(bytes("Tampa"), bytes("rocks"));
    String value = asString(db.get(bytes("Tampa")));
    db.delete(bytes("Tampa"));

Performing Batch/Bulk/Atomic Updates.

    WriteBatch batch = db.createWriteBatch();
    try {
      batch.delete(bytes("Denver"));
      batch.put(bytes("Tampa"), bytes("green"));
      batch.put(bytes("London"), bytes("red"));

      db.write(batch);
    } finally {
      // Make sure you close the batch to avoid resource leaks.
      batch.close();
    }

Iterating key/values.

    DBIterator iterator = db.iterator();
    try {
      for(iterator.seekToFirst(); iterator.hasNext(); iterator.next()) {
        String key = asString(iterator.peekNext().getKey());
        String value = asString(iterator.peekNext().getValue());
        System.out.println(key+" = "+value);
      }
    } finally {
      // Make sure you close the iterator to avoid resource leaks.
      iterator.close();
    }

Working against a Snapshot view of the Database.

    ReadOptions ro = new ReadOptions();
    ro.snapshot(db.getSnapshot());
    try {
      
      // All read operations will now use the same 
      // consistent view of the data.
      ... = db.iterator(ro);
      ... = db.get(bytes("Tampa"), ro);

    } finally {
      // Make sure you close the snapshot to avoid resource leaks.
      ro.snapshot().close();
    }

Using a custom Comparator.

    DBComparator comparator = new DBComparator(){
        public int compare(byte[] key1, byte[] key2) {
            return new String(key1).compareTo(new String(key2));
        }
        public String name() {
            return "simple";
        }
        public byte[] findShortestSeparator(byte[] start, byte[] limit) {
            return start;
        }
        public byte[] findShortSuccessor(byte[] key) {
            return key;
        }
    };
    Options options = new Options();
    options.comparator(comparator);
    DB db = factory.open(new File("example"), options);
    
Disabling Compression

    Options options = new Options();
    options.compressionType(CompressionType.NONE);
    DB db = factory.open(new File("example"), options);

Configuring the Cache
    
    Options options = new Options();
    options.cacheSize(100 * 1048576); // 100MB cache
    DB db = factory.open(new File("example"), options);

Getting approximate sizes.

    long[] sizes = db.getApproximateSizes(new Range(bytes("a"), bytes("k")), new Range(bytes("k"), bytes("z")));
    System.out.println("Size: "+sizes[0]+", "+sizes[1]);
    
Getting database status.

    String stats = db.getProperty("leveldb.stats");
    System.out.println(stats);

Getting informational log messages.

    Logger logger = new Logger() {
      public void log(String message) {
        System.out.println(message);
      }
    };
    Options options = new Options();
    options.logger(logger);
    DB db = factory.open(new File("example"), options);

Destroying a database.
    
    Options options = new Options();
    factory.destroy(new File("example"), options);

Repairing a database.
    
    Options options = new Options();
    factory.repair(new File("example"), options);

Using a memory pool to make native memory allocations more efficient:

    JniDBFactory.pushMemoryPool(1024 * 512);
    try {
        // .. work with the DB in here, 
    } finally {
        JniDBFactory.popMemoryPool();
    }
    
## Building

### Prerequisites 

* GNU compiler toolchain
* [Maven 3](http://maven.apache.org/download.html)

### Supported Platforms

The following worked for me on:

 * Ubuntu 14.04, 16.06, 18.04 (64 bit)
 
 Run : apt-get install autoconf libtool

### Build Procedure

Then download the snappy, pebblesdb, and leveldbjni project source code:

    wget https://src.fedoraproject.org/lookaside/pkgs/snappy/snappy-1.0.5.tar.gz/4c0af044e654f5983f4acbf00d1ac236/snappy-1.0.5.tar.gz
    tar -zxvf snappy-1.0.5.tar.gz
    git clone https://github.com/utsaslab/pebblesdb.git
    git clone https://github.com/utsaslab/leveldbjni.git
    export SNAPPY_HOME=`cd snappy-1.0.5; pwd`
    export PEBBLESDB_HOME=`cd pebblesdb; pwd`
    export LEVELDBJNI_HOME=`cd leveldbjni; pwd`

<!-- In cygwin that would be
    export SNAPPY_HOME=$(cygpath -w `cd snappy-1.0.5; pwd`)
    export PEBBLESDB_HOME=$(cygpath -w `cd pebblesdb; pwd`)
    export LEVELDBJNI_HOME=$(cygpath -w `cd leveldbjni; pwd`)
-->

Compile the snappy project.  This produces a static library.

    cd ${SNAPPY_HOME}
    ./configure --disable-shared --with-pic
    make
    
Patch and Compile the leveldb project.  This produces a static library. 
    
    cd ${PEBBLESDB_HOME}
    git apply ../leveldbjni/pebblesdb.patch
    mkdir -p build && cd build
    cmake .. && make install -j16


Now use maven to build the leveldbjni project. 
    
    cd ${LEVELDBJNI_HOME}
    chmod a+x setup.sh
    ./setup.sh
    export LEVELDB_HOME=`cd pebblesdb; pwd`
    export platform="linux64"
    mvn clean install -P download -P ${platform}

Here, ${platform} can be one of the following platform identifiers (depending on the platform you are building on):

* osx
* linux32
* linux64
* win32
* win64
* freebsd64

If your platform does not have the right auto-tools levels available
just copy the `leveldbjni-${version}-SNAPSHOT-native-src.zip` artifact
from a platform the does have the tools available, then add the
following argument to your maven build:

    -Dnative-src-url=file:leveldbjni-${verision}-SNAPSHOT-native-src.zip

### Build Results

* `leveldbjni/target/leveldbjni-${version}.jar` : The java class file to the library.
* `leveldbjni/target/leveldbjni-${version}-native-src.zip` : A GNU style source project which you can use to build the native library on other systems.
* `leveldbjni-${platform}/target/leveldbjni-${platform}-${version}.jar` : A jar file containing the built native library using your currently platform.

## Running YCSB Workloads with PebblesDB

Firstly build this project for the specific platform. Refer above for building instructions.

Then, clone the following fork of YCSB.

    git clone https://github.com/utsaslab/YCSB.git
    export YCSB_HOME=`cd YCSB; pwd`
    cd ${YCSB_HOME}

Copy the jars created by LevelDbJni.

    mkdir ${YCSB_HOME}/pebblesdb/lib
    cp ${LEVELDBJNI_HOME}/leveldbjni/target/*.jar ${YCSB_HOME}/pebblesdb/lib
    cp ${LEVELDBJNI_HOME}/leveldbjni-{platform}/target/*.jar ${YCSB_HOME}/pebblesdb/lib

Build the pebblesDB binding.

    mvn -pl com.yahoo.ycsb:pebblesdb-binding -am clean package

Run the YCSB workloads. Example command :-
    
     java -cp pebblesdb/target/*:pebblesdb/target/dependency/*:pebblesdb/lib/*: com.yahoo.ycsb.Client -load -db com.yahoo.ycsb.db.PebblesDbClient -P workloads/workloada