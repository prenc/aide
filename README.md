# AIDE-SERVER
	
TODO:
client installation script:
	expect:
		check if /etc/sudoers has doubled lines*
	bash:
		
new script (no name yet)
	create tar command basing on client's config (--exclude)
	script can be invoked anytime with option -i and then creates backup from scratch (especially when client's config file is reconfigured)
	adding and removing files from backup according to changes detected by AIDE
	when file change detected, send old version (filename.old.unixtime) to recovery catalog and update backup 
	improve AIDE log file by showing differences between versions
	error handling:
		not enough space for new backup file
		
Useful things:
	ssh aide_spool@dockerserver tar czf - /root/aide/test > backup-$(date +%s).tar.gz

	tar:
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
