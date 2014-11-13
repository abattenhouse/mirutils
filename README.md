# mirUtils README

## Release bundle downloads

[https://sourceforge.net/projects/mirutils/](https://sourceforge.net/projects/mirutils/)

## Documentation

[http://mirutils.sourceforge.net/](http://mirutils.sourceforge.net/)
  
## Full source code

[https://github.com/abattenhouse/mirutils](https://github.com/abattenhouse/mirutils)

## Quick Start
Assuming the install directory is /opt/mirUtils-v1.0.0-r26

```
cd /opt/mirUtils-v1.0.0-r26 
../mirUtils ./data/mb_test_small.sort.bam
```

**_Note:_** 
The mirUtils executable should not be moved from its bundle directory,
as it uses relative paths to access its miRBase aritifacts in
the mirbase sub-directory. For easier access, the bundle directory
can be added to the PATH, or mirUtils can be invoked from a symbolic link.

