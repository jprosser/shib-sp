#!/bin/sh

#for passed-in env vars, remove spaces and replace any ; with : in usertoken env var since we will use ; as a delimiter
export USERTOKEN="${USERTOKEN//;/:}"
export USERTOKEN="${USERTOKEN// /}"
export ENV="${ENV//;/:}"
export ENV="${ENV// /}"

# Apache httpd's ErrorLogFormat only expands environment variables for messages
# generated in the context of a request, so the only known reliable way to
# include ENV and USERTOKEN is to write the config when the container starts.
echo '# This file is generated in startup.sh. Do Not Modify!' > /etc/httpd/conf.d/10_errorlogformat.conf
echo -e "\nErrorLogFormat \"httpd;error_log;${ENV};${USERTOKEN};[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i\"" >> /etc/httpd/conf.d/10_errorlogformat.conf

# generic console logging pipe for anyone
mkfifo -m 666 /tmp/logpipe
cat <> /tmp/logpipe 1>&2 &

mkfifo -m 666 /tmp/logcrond
(cat <> /tmp/logcrond  | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "crond;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/loghttpd
(cat <> /tmp/loghttpd | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "httpd;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logsuperd
(cat <> /tmp/logsuperd | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "supervisord;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logshibd
(cat <> /tmp/logshibd | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "shibd;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

#launch supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf

