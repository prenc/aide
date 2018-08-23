# AIDE-SERVER :muscle::muscle::muscle:
	
## TODO:
### client installation script:
- expect:
  - [ ] check whether */etc/sudoers* has doubled lines
  - [ ] inform bash part about progress -> pretty processing
  - [ ] more specific errors (wrong password)
- bash:
  - [ ] pretty processing :heart_eyes_cat:
### backup and recovery:
- [ ] create tar command basing on client's config (--exclude)
- [ ] script can be invoked anytime with option -i and then creates backup from scratch (especially when client's config is reconfigured)
- [ ] adding and removing files from backup according to changes detected by AIDE
- [ ] when file change detected, send old version (*filename.old.unixtime*) to recovery directory and update backup :fire:
- [ ] improve AIDE log file by showing differences between versions
- [ ] error handling:
	- [ ] not enough space for new backup file

### documentation update:
- client's hostname has to be unique
- add script names and specification


## Useful things:
* ssh aide_spool@dockerserver tar czf - /root/aide/test > backup-$(date +%s).tar.gz

* tar:


     -c create new archive
     -d difference between archive and file system
     -v, --verbose
     verbosely list files processed
     -z, --gzip
     filter the archive through gzip
     -f, --file=ARCHIVE
     use archive file or device ARCHIVE
     -A, --catenate, --concatenate
     append tar files to an archive
     -r, --append
     append files to the end of an archive
     -u, --update
     only append files newer than copy in archive
     -x, --extract, --get
     extract files from an archive
     --delete
     delete from the archive (not on mag tapes!)??
