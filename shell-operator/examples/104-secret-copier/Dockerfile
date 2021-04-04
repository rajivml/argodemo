FROM flant/shell-operator:latest
ADD hooks /hooks
RUN chmod u+x /hooks/*
RUN chmod u-x /hooks/common/functions.sh
