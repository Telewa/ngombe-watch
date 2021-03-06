/**
 Copyright 2013 ILRI, www.ilri.org

 Emmanuel Telewa  <e.telewa@cgiar.org>
 Kihara Absolomon <a.kihara@cgiar.org>
 
 This file is part of ngombe-watch.

 server.c is a script that should be run on a server, that is used to
 receive data from the clients(waspmotes) and save the data into a 
 MySQL database. It uses TCP/IP protocols.
 
 ngombe-watch is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 ngombe-watch is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with ngombe-watch.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <mysql.h>
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <json/json.h>
#define MAXSIZE 300

void readLinesFromFile(char * filename);
int storeToDB(char * ax, char *ay, char *az, char *temp, char *battery, char *tm, char *dt, char *lt, char *ln, char *al, char *sp, char *cs);
char *of = "received_data.txt"; //the name of the output file

main()
{
    readLinesFromFile(of);
}

void readLinesFromFile(char * filename)
{
    FILE *file = fopen(filename, "r");
    if (file != NULL)
    {
        char line [ MAXSIZE ]; /* or other suitable maximum line size */
        while (fgets(line, sizeof line, file) != NULL) /* read a line */
        {
            if (strlen(line) > 1)
            {
                //remove the '{' and '}'
                line[0] = ' ';
                line[strlen(line) - 2] = '\0';
                //remove the extra spaces
                char *ch = line;
                char *p1 = ch;
                char *p2 = ch;
                p1 = ch;
                while (*p1 != 0)
                {
                    if (isspace(*p1) || (*p1) == '\"')
                    {
                        ++p1;
                    }
                    else
                        *p2++ = *p1++;
                }
                *p2 = 0;

                //now the string without extra spaces is stored in 'ch'
                printf("Splitting string \"%s\" into tokens:\n", ch);
                char * keyV[12];

                char *str = line;
                char * pch;
                pch = strtok(str, ",");
                int i = 0;
                while (pch != NULL)
                {
                    keyV[i] = pch;
                    pch = strtok(NULL, ",");
                    i++;
                }

                //now tokenize them further
                //now each of those tokens is a key-value pair
                char *values[24];
                int k, x;
                x = 0;
                for (k = 0; k < i; k++)
                {
                    char *str2 = keyV[k];
                    char * pch2;
                    pch2 = strtok(str2, ":");
                    while (pch2 != NULL)
                    {
                        values[x++] = pch2;
                        pch2 = strtok(NULL, ":");
                    }
                }
                //call function to insert to db with the cprrect params
                storeToDB(values[1], values[3], values[5], values[5], values[7], values[9], values[11], values[13], values[15], values[17], values[19], values[21]);
                memset(line, 0, sizeof (line));
                //break;
            }
        }
        fclose(file);
    }
    else
    {
        perror(filename); /* why didn't the file open? */
    }
}

int storeToDB(char * ax, char *ay, char *az, char *temp, char *battery, char *tm, char *dt, char *lt, char *ln, char *al, char *sp, char *cs)
{
    int stored = 0;
    MYSQL *conn;
    MYSQL_ROW row;
    char *server = "localhost";
    char *user = "root";
    char *password = "root"; /* set me first */
    char *database = "ILRI_DB";
    char *table_name = "COW_DATA";
    conn = mysql_init(NULL);

    /* Connect to database */
    if (!mysql_real_connect(conn, server, user, password, database, 0, NULL, 0))
    {
        fprintf(stderr, "%s\n", mysql_error(conn));
        exit(1);
    }

    char command[300];
    memset(command, 0, sizeof (command));
    strcpy(command, "INSERT INTO ");
    strcat(command, table_name);
    strcat(command, "(");
    strcat(command, "ax,ay,az,temp,battery,tm,dt,lt,ln,al,sp,cs) values(");
    strcat(command, "'");
    strcat(command, ax);
    strcat(command, "','");
    strcat(command, ay);
    strcat(command, "','");
    strcat(command, az);
    strcat(command, "','");
    strcat(command, temp);
    strcat(command, "','");
    strcat(command, battery);
    strcat(command, "','");
    strcat(command, tm);
    strcat(command, "','");
    strcat(command, dt);
    strcat(command, "','");
    strcat(command, lt);
    strcat(command, "','");
    strcat(command, ln);
    strcat(command, "','");
    strcat(command, al);
    strcat(command, "','");
    strcat(command, sp);
    strcat(command, "','");
    strcat(command, cs);
    strcat(command, "')");

    /* send SQL query */
    if (mysql_query(conn, command))
    {
        fprintf(stderr, "%s\n\n", mysql_error(conn));
        stored = 0;
    }
    else
    {
        printf("Data inserted\n");
        stored = 1;
    }

    /* close connection */
    mysql_close(conn);
    return stored;
}
