#!/bin/bash

##########################################################################
# Copyright 2017, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of CCseqBasic5 .                                     #
#                                                                        #
# CCseqBasic5 is free software: you can redistribute it and/or modify    #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# CCseqBasic5 is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with CCseqBasic5.  If not, see <http://www.gnu.org/licenses/>.   #
##########################################################################

# This just lists the qsub environment after sun grid engine (SGE) job has been started.
# The below is taken from :
# https://docs.oracle.com/cd/E19957-01/820-0699/chp4-21/index.html

echo 'ARC The architecture name of the node on which the job is running. The name is compiled into the sge_execd binary.'
echo "ARC ${ARC}"
echo ''
echo 'SGE_ROOT The root directory of the grid engine system as set for sge_execd before startup, or the default /usr/SGE directory.'
echo "SGE_ROOT ${SGE_ROOT}"
echo ''
echo 'SGE_BINARY_PATH The directory in which the grid engine system binaries are installed.'
echo "SGE_BINARY_PATH ${SGE_BINARY_PATH}"
echo ''
echo 'SGE_CELL The cell in which the job runs.'
echo "SGE_CELL ${SGE_CELL}"
echo ''
echo 'SGE_JOB_SPOOL_DIR The directory used by sge_shepherd to store job-related data while the job runs.'
echo "SGE_JOB_SPOOL_DIR ${SGE_JOB_SPOOL_DIR}"
echo ''
echo 'SGE_O_HOME The path to the home directory of the job owner on the host from which the job was submitted.'
echo "SGE_O_HOME ${SGE_O_HOME}"
echo ''
echo 'SGE_O_HOST The host from which the job was submitted.'
echo "SGE_O_HOST ${SGE_O_HOST}"
echo ''
echo 'SGE_O_LOGNAME The login name of the job owner on the host from which the job was submitted.'
echo "SGE_O_LOGNAME ${SGE_O_LOGNAME}"
echo ''
echo 'SGE_O_MAIL The content of the MAIL environment variable in the context of the job submission command.'
echo "SGE_O_MAIL ${SGE_O_MAIL}"
echo ''
echo 'SGE_O_PATH The content of the PATH environment variable in the context of the job submission command.'
echo "SGE_O_PATH ${SGE_O_PATH}"
echo ''
echo 'SGE_O_SHELL The content of the SHELL environment variable in the context of the job submission command.'
echo "SGE_O_SHELL ${SGE_O_SHELL}"
echo ''
echo 'SGE_O_TZ The content of the TZ environment variable in the context of the job submission command.'
echo "SGE_O_TZ ${SGE_O_TZ}"
echo ''
echo 'SGE_O_WORKDIR The working directory of the job submission command.'
echo "SGE_O_WORKDIR ${SGE_O_WORKDIR}"
echo ''
echo 'SGE_CKPT_ENV The checkpointing environment under which a checkpointing job runs. The checkpointing environment is selected with the qsub -ckpt command.'
echo "SGE_CKPT_ENV ${SGE_CKPT_ENV}"
echo ''
echo 'SGE_CKPT_DIR The path ckpt_dir of the checkpoint interface. Set only for checkpointing jobs. For more information, see the checkpoint(5) man page.'
echo "SGE_CKPT_DIR ${SGE_CKPT_DIR}"
echo ''
echo 'SGE_STDERR_PATH The path name of the file to which the standard error stream of the job is diverted.'
echo "SGE_STDERR_PATH ${SGE_STDERR_PATH}"
echo ''
echo 'SGE_STDOUT_PATH The path name of the file to which the standard output stream of the job is diverted.' 
echo "SGE_STDOUT_PATH ${SGE_STDOUT_PATH}"
echo ''
echo 'SGE_TASK_ID The task identifier in the array job represented by this task.'
echo "SGE_TASK_ID ${SGE_TASK_ID}"
echo ''
echo 'ENVIRONMENT Always set to BATCH. This variable indicates that the script is run in batch mode.'
echo "ENVIRONMENT ${ENVIRONMENT}"
echo ''
echo 'HOME The users home directory path as taken from the passwd file.'
echo "HOME ${HOME}"
echo ''
echo 'HOSTNAME The host name of the node on which the job is running.'
echo "HOSTNAME ${HOSTNAME}"
echo ''
echo 'JOB_ID A unique identifier assigned by the sge_qmaster daemon when the job was submitted. The job ID is a decimal integer from 1 through 9,999,999.'
echo "JOB_ID ${JOB_ID}"
echo ''
echo 'JOB_NAME The job name, which is built from the file name provided with the qsub command, a period, and the digits of the job ID. You can override this default with qsub -N.'
echo "JOB_NAME ${JOB_NAME}"
echo ''
echo 'LOGNAME The users login name as taken from the passwd file.'
echo "LOGNAME ${LOGNAME}"
echo ''
echo 'NHOSTS The number of hosts in use by a parallel job.'
echo "NHOSTS ${NHOSTS}"
echo ''
echo 'NQUEUES The number of queues that are allocated for the job. This number is always 1 for serial jobs.'
echo "NQUEUES ${NQUEUES}"
echo ''
echo 'NSLOTS The number of queue slots in use by a parallel job.'
echo "NSLOTS ${NSLOTS}"
echo ''
echo 'PATH A default shell search path of: /usr/local/bin:/usr/ucb:/bin:/usr/bin.'
echo "PATH ${PATH}"
echo ''
echo 'PE The parallel environment under which the job runs. This variable is for parallel jobs only.'
echo "PE ${PE}"
echo ''
echo 'PE_HOSTFILE The path of a file that contains the definition of the virtual parallel machine that is assigned to a parallel job by the grid engine system. '
echo 'This variable is used for parallel jobs only. See the description of the $pe_hostfile parameter in sge_pe for details on the format of this file.'
echo "PE_HOSTFILE ${PE_HOSTFILE}"
echo ''
echo 'QUEUE The name of the queue in which the job is running.'
echo "QUEUE ${QUEUE}"
echo ''
echo 'REQUEST The request name of the job. The name is either the job script file name or is explicitly assigned to the job by the qsub -N command.'
echo "REQUEST ${REQUEST}"
echo ''
echo 'RESTARTED Indicates whether a checkpointing job was restarted. If set to value 1, the job was interrupted at least once. The job is therefore restarted.'
echo "RESTARTED ${RESTARTED}"
echo ''
echo 'SHELL The users login shell as taken from the passwd file. Note – SHELL is not necessarily the shell that is used for the job.'
echo "SHELL ${SHELL}"
echo ''
echo 'TMPDIR The absolute path to the jobs temporary working directory.'
echo "TMPDIR ${TMPDIR}"
echo ''
echo 'TMP The same as TMPDIR. This variable is provided for compatibility with NQS.'
echo "TMP ${TMP}"
echo ''
echo 'TZ The time zone variable imported from sge_execd, if set.'
echo "TZ ${TZ}"
echo ''
echo 'USER The users login name as taken from the passwd file.'
echo "USER ${USER}"


