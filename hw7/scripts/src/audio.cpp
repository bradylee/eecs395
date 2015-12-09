#include <stdio.h>
#include <stdlib.h>
#include <sys/soundcard.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <iostream>
#include <string>
#include <alsa/asoundlib.h>

#include "audio.h"

using namespace std;


int audio_init(int sampling_rate, const std::string device_name)
{
    string dev_name = !device_name.empty() ? device_name : "/dev/dsp";

//    int fd = open( dev_name.c_str(), O_WRONLY );
    int fd = open("cmp.dat", O_WRONLY);
    if ( fd < 0)
    {
        printf( "Failed to open file.");
        return -1;
    }
    return fd;
}



void audio_tx( int fd, int sampling_rate, int *lt_channel, int *rt_channel, int n_samples )
{
    double CHUNK_TIME = 0.005;
    int chunk_size = (int)(sampling_rate * CHUNK_TIME);
    short * buffer = new short[chunk_size * 2];

    for (int i = 0; i < n_samples; i += chunk_size)
    {
        for (int j = 0; j < chunk_size; j++)
        {
            buffer[2*j+0] = (short)lt_channel[j];
            buffer[2*j+1] = (short)rt_channel[j];
        }

        lt_channel += chunk_size;
        rt_channel += chunk_size;
        
        if ( write(fd, buffer, 2*chunk_size*sizeof(short)) < 0 )
        {
            printf( "Failed to write audio output!\n" );
            return;
        }
    }

    delete buffer;
}
