-- db_h=main
-- app=a510
-- version=5.0

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `datetime_rec_start` datetime default NULL,
  `datetime_rec_end` datetime default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `datetime_rec_start` datetime default NULL,
  `datetime_rec_end` datetime default NULL,
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_attrs` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_attrs_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_category` bigint(20) unsigned default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `order_id` int(10) unsigned NOT NULL,
  `description` text character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _video.ID_entity
  `part_id` mediumint(8) unsigned NOT NULL default '0',
  `datetime_create` datetime NOT NULL,
  `thumbnail_lock` char(1) character set ascii NOT NULL default 'N',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _video.ID_entity
  `part_id` mediumint(8) unsigned NOT NULL default '0',
  `datetime_create` datetime NOT NULL,
  `thumbnail_lock` char(1) character set ascii NOT NULL default 'N',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_emo` ( -- experimental EMO characteristics
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _video_part.ID
  `datetime_create` datetime NOT NULL,
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_cry` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_video_part_emo_view` AS (
	SELECT
		emo.ID,
		(emo.emo_angry + emo.emo_confused + emo.emo_cry + emo.emo_omg + emo.emo_smile) AS emo_all,
		(emo.emo_angry/((emo.emo_angry + emo.emo_confused + emo.emo_cry + emo.emo_omg + emo.emo_smile)/100))
			AS emo_angry_perc,
		(emo.emo_confused/((emo.emo_angry + emo.emo_confused + emo.emo_cry + emo.emo_omg + emo.emo_smile)/100))
			AS emo_confused_perc,
		(emo.emo_cry/((emo.emo_angry + emo.emo_confused + emo.emo_cry + emo.emo_omg + emo.emo_smile)/100))
			AS emo_cry_perc,
		(emo.emo_omg/((emo.emo_angry + emo.emo_confused + emo.emo_cry + emo.emo_omg + emo.emo_smile)/100))
			AS emo_omg_perc,
		(emo.emo_smile/((emo.emo_angry + emo.emo_confused + emo.emo_cry + emo.emo_omg + emo.emo_smile)/100))
			AS emo_smile_perc
	FROM
		`/*db_name*/`.`/*app*/_video_part_emo` AS emo
)

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_video_part_emo_viewEQ` AS (
	SELECT
		emo1.ID AS emo1_ID,
		emo2.ID AS emo2_ID,
		ABS(emo1.emo_angry_perc - emo2.emo_angry_perc) AS emo_angry_diff,
		ABS(emo1.emo_confused_perc - emo2.emo_confused_perc) AS emo_confused_diff,
		ABS(emo1.emo_cry_perc - emo2.emo_cry_perc) AS emo_cry_diff,
		ABS(emo1.emo_omg_perc - emo2.emo_omg_perc) AS emo_omg_diff,
		ABS(emo1.emo_smile_perc - emo2.emo_smile_perc) AS emo_smile_diff,
		(100-((
			ABS(emo1.emo_angry_perc - emo2.emo_angry_perc) +
			ABS(emo1.emo_confused_perc - emo2.emo_confused_perc) +
			ABS(emo1.emo_cry_perc - emo2.emo_cry_perc) +
			ABS(emo1.emo_omg_perc - emo2.emo_omg_perc) +
			ABS(emo1.emo_smile_perc - emo2.emo_smile_perc)
		)/5)) AS EQ
	FROM
		`/*db_name*/`.`/*app*/_video_part_emo_view` AS emo1,
		`/*db_name*/`.`/*app*/_video_part_emo_view` AS emo2
	WHERE
		emo1.ID <> emo2.ID AND
		emo2.emo_all > emo1.emo_all/100 AND
		emo1.emo_all > emo2.emo_all/100 AND
		emo2.emo_all > 1 AND
		emo1.emo_all > 1
)

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_emo_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `datetime_create` datetime NOT NULL,
  `emo_angry` int(10) unsigned NOT NULL default '0',
  `emo_confused` int(10) unsigned NOT NULL default '0',
  `emo_cry` int(10) unsigned NOT NULL default '0',
  `emo_omg` int(10) unsigned NOT NULL default '0',
  `emo_sad` int(10) unsigned NOT NULL default '0',
  `emo_smile` int(10) unsigned NOT NULL default '0',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_attrs` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _video_part.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `description` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_attrs_j` (
  `ID` mediumint(8) unsigned NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _video_part.ID
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `description` tinytext character set utf8 collate utf8_unicode_ci NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_file` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL, -- rel _video_part.ID
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `video_width` int(10) unsigned NOT NULL,
  `video_height` int(10) unsigned NOT NULL,
  `video_codec` varchar(50) character set ascii NOT NULL,
  `video_fps` float NOT NULL,
  `video_bitrate` int(10) unsigned NOT NULL,
  `audio_codec` varchar(50) character set ascii NOT NULL,
  `audio_bitrate` int(10) unsigned NOT NULL,
  `length` time NOT NULL,
  `file_alt_src` varchar(250) character set ascii default NULL,
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `from_parent` char(1) character set ascii NOT NULL default 'N', -- is this file generated from parent video_part_file?
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`ID_format`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_part_file_j` (
  `ID` mediumint(8) unsigned zerofill NOT NULL auto_increment,
  `ID_entity` mediumint(8) unsigned default NULL,
  `ID_format` bigint(20) unsigned NOT NULL,
  `name` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `datetime_create` datetime NOT NULL,
  `video_width` int(10) unsigned NOT NULL,
  `video_height` int(10) unsigned NOT NULL,
  `video_codec` varchar(50) character set ascii NOT NULL,
  `video_fps` float NOT NULL,
  `video_bitrate` int(10) unsigned NOT NULL,
  `audio_codec` varchar(50) character set ascii NOT NULL,
  `audio_bitrate` int(10) unsigned NOT NULL,
  `length` time NOT NULL,
  `file_alt_src` varchar(250) character set ascii default NULL,
  `file_size` bigint(20) unsigned default NULL,
  `file_checksum` varchar(128) character set ascii collate ascii_bin NOT NULL,
  `file_ext` varchar(120) character set ascii NOT NULL,
  `from_parent` char(1) character set ascii NOT NULL default 'N',
  `status` char(1) character set ascii NOT NULL default 'Y',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_visit` (
  `datetime_event` datetime NOT NULL,
  `ID_user` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `ID_video` bigint(20) NOT NULL,
  PRIMARY KEY  (`datetime_event`,`ID_user`,`ID_video`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_cat` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_cat_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `posix_owner` varchar(8) character set ascii collate ascii_bin NOT NULL,
  `posix_group` int(10) unsigned NOT NULL,
  `posix_perms` char(9) character set ascii NOT NULL default 'rwxrw-r--',
  `datetime_create` datetime NOT NULL,
  `lng` char(2) character set ascii NOT NULL default '',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_format` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `process` text character set ascii NOT NULL,
  `required` char(1) NOT NULL default 'Y',
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`,`lng`),
  UNIQUE KEY `UNI_1` (`ID_charindex`,`lng`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_video_format_j` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL,
  `process` text character set ascii NOT NULL,
  `required` char(1) NOT NULL default 'Y',
  `lng` char(2) character set ascii NOT NULL default 'xx',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------

CREATE OR REPLACE VIEW `/*db_name*/`.`/*app*/_video_view` AS (
	SELECT
		CONCAT(video.ID_entity,'_',video.ID,'_',video_attrs.lng,'_',video_format.ID) AS ID,
		
		video.ID_entity AS ID_entity_video,
		video.ID AS ID_video,
		video_attrs.ID AS ID_attrs,
		video_format.ID AS ID_format,
		video_format.name AS ID_format_name,
		video_part.ID AS ID_part,
		video_part_attrs.ID AS ID_part_attrs,
		video_part_file.ID AS ID_part_file,
		
		video.datetime_rec_start,
		DATE(video.datetime_rec_start) AS date_recorded,
		
		video_attrs.ID_category,
		video_cat.name AS ID_category_name,
		
		video.posix_owner,
		video.posix_group,
		video.posix_perms,
		
		video_attrs.name,
		video_attrs.description,
		video_attrs.order_id,
		video_attrs.lng,
		
		video_part_attrs.name AS part_name,
		video_part_attrs.description AS part_description,
		video_part.part_id AS part_id,
		video_part_attrs.lng AS part_lng,
		
		video_part_file.video_width,
		video_part_file.video_height,
		video_part_file.video_bitrate,
		video_part_file.length,
		video_part_file.file_size,
		video_part_file.file_ext,
		
		CONCAT(video_format.ID,'/',SUBSTR(video_part_file.ID,1,4),'/',video_part_file.name,'.',video_part_file.file_ext) AS file_part_path,
		
		IF
		(
			(
				video.status LIKE 'Y' AND
				video_attrs.status LIKE 'Y' AND
				video_format.status IN ('Y','L') AND
				video_part.status LIKE 'Y' AND
				video_part_file.status LIKE 'Y'
			),
			 'Y', 'U'
		) AS status
		
	FROM
		`/*db_name*/`.`/*app*/_video` AS video
	LEFT JOIN `/*db_name*/`.`/*app*/_video_attrs` AS video_attrs ON
	(
		video_attrs.ID_entity = video.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_video_part` AS video_part ON
	(
		video_part.ID_entity = video.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_video_part_attrs` AS video_part_attrs ON
	(
		video_part_attrs.ID_entity = video_part.ID AND
		video_part_attrs.lng = video_attrs.lng
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_video_part_file` AS video_part_file ON
	(
		video_part_file.ID_entity = video_part.ID
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_video_format` AS video_format ON
	(
		video_format.ID_entity = video_part_file.ID_format
	)
	LEFT JOIN `/*db_name*/`.`/*app*/_video_cat` AS video_cat ON
	(
		video_cat.ID = video_attrs.ID_category
	)
	
	WHERE
		video.ID AND
		video_attrs.ID AND
		video_part_attrs.ID AND
		video_format.ID AND
		video_part.ID AND
		video_part_file.ID
)

-- --------------------------------------------------

