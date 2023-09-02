#!/bin/sh

restic snapshots ${RESTIC_INIT_ARGS} &>/dev/null
status=$?
echo "Check Repo status $status"

if [ $status != 0 ]; then
    echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
    restic init ${RESTIC_INIT_ARGS}

    init_status=$?
    echo "Repo init status $init_status"

    if [ $init_status != 0 ]; then
        echo "Failed to init the repository: '${RESTIC_REPOSITORY}'"
        exit 1
    fi
fi

echo "Sending start signal to healthchecks.io"
curl --silent --output /dev/null $CHECK_URL/start

start=`date +%s`
echo "===== Starting backup at $(date +"%Y-%m-%d %H:%M:%S") ====="

restic backup /data ${RESTIC_JOB_ARGS}
backupRC=$?

if [[ $backupRC == 0 ]]; then
    echo "Sending success signal to healthchecks.io"
    curl --silent --output /dev/null $CHECK_URL
else
    echo "Backup failed with Status ${backupRC}"
    restic unlock
    echo "Sending fail signal to healthchecks.io"
    curl --silent --output /dev/null $CHECK_URL/fail
fi

#if [[ $backupRC == 0 ]] && [ -n "${RESTIC_FORGET_ARGS}" ]; then
#    echo "Forget about old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"
#    restic forget ${RESTIC_FORGET_ARGS}
#    rc=$?
#    echo "Finished forget at $(date)"
#    if [[ $rc == 0 ]]; then
#        echo "Forget Successful"
#    else
#        echo "Forget Failed with Status ${rc}"
#        restic unlock
#    fi
#fi

end=`date +%s`
echo "===== Finished backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds ====="