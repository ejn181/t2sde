
if [ "$prefix_auto" = 1 ] ; then
  if [ "$NO_SANITY_CHECK" ] ; then
	prefix=$ROCKCFG_PKG_KDE3_CORE_PREFIX
  else 
	for dir in usr opt/kde3 $ROCKCFG_PKG_KDE3_CORE_PREFIX ; do
		[ -f "$root/$dir/bin/artsd" ] && prefix="$dir"
	done

	[ ! -f "$root/$prefix/bin/artsd" ] &&
	abort "kdelibs (artsd) is not installed (in prefix $prefix)!"
  fi

  set_confopt
fi

# make sure the right qt and kde libs are used
export LD_LIBRARY_PATH="$QTDIR/lib:/$prefix/lib:$LD_LIBRARY_PATH"

# KDE specific configure options
var_append confopt " " "--with-qt-dir=$QTDIR \
                        --with-qt-includes=$QTDIR/include \
                        --with-qt-libraries=$QTDIR/lib"

# some feature and optimization settings ...

pkginstalled openldap && var_append confopt " " "--with-ldap=$root/$pkg_openldap_prefix"
var_append confopt " " "--with-xinerama --enable-dnotify"
var_append confopt " " "--enable-final"
[ $arch = x86 ] && var_append confopt " " "--enable-fast-malloc=full"

