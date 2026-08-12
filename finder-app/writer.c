#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <syslog.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    int rc = 1;

    openlog("writer", LOG_PID, LOG_USER);

    if (argc != 3)
    {
        syslog(LOG_ERR, "2 arguments required!");
        return rc;

    } else {

        syslog(LOG_DEBUG, "Openning the file \"%s\"", argv[1]);
        int fd = open(argv[1], O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR |
                                                             S_IRGRP | S_IWGRP | 
                                                             S_IROTH | S_IWOTH);

        if (fd == -1)
        {
            syslog(LOG_ERR, "Failed to open the file!");
            return rc;

        } else {
            
            syslog(LOG_DEBUG, "Writing \"%s\" to \"%s\"", argv[2], argv[1]);
            
            ssize_t w;
            w = write(fd, argv[2], strlen(argv[2]));

            if (w == -1)
            {
                syslog(LOG_ERR, "Failed to write \"%s\" to \"%s\"! Closing now!", argv[2], argv[1]);
                close(fd);
                return rc;

            } else {
                
                syslog(LOG_DEBUG, "Closing the file");
                close(fd);

                rc = 0;
            }
        }
    }

    return rc;
}