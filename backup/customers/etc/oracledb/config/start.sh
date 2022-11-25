for f in /docker-entrypoint-initdb.d/*; do
  case "$f" in
    *.sql)    echo "$0: running $f"; echo "exit" | /u01/app/oracle/product/11.2.0/xe/bin/sqlplus "system/oracle" @"$f"; echo ;;
  esac
  echo
done
