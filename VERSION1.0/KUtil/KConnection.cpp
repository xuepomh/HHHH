#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <assert.h>
#include <signal.h>
#include <sys/time.h>
#include "KConnection.h"
#include "cpLog.h"


KMutex KConnection::closeMutex;

KConnection::KConnection( const KConnection& other )
{
	_connId = other._connId;
	_live = other._live;
	_connAddrLen = other._connAddrLen;
	_blocking = other._blocking;
	_timeout = other._timeout;
	
	memcpy( (void*)&_connAddr, (void*)&other._connAddr, sizeof( _connAddr ) );
	closeMutex.lock();
	useNum = other.useNum;
	if ( useNum != NULL )
		(*useNum)++;
	closeMutex.unlock();
}

KConnection&
KConnection::operator=( const KConnection& other )
{
	if ( this != &other )
	{
		if ( _live )
		{
			close();
			_live = false;
		}
		closeMutex.lock();
		_connId = other._connId;
		_live = other._live;
		_connAddrLen = other._connAddrLen;
		_blocking = other._blocking;
		_timeout = other._timeout;
		
		memcpy( (void*)&_connAddr, (void*)&other._connAddr, sizeof(_connAddr) );
		useNum = other.useNum;
		if ( NULL != useNum )
			(*useNum)++;
		closeMutex.unlock();
	}
	return *this;
}

int
KConnection::readLine( void* dataRead, int maxlen, int timeout )
{
	memset( dataRead, 0, maxlen );
	char c;
	int rc, i;
	char* ptr = (char*)dataRead;
	for( i = 1; i<maxlen; i++ )
    {
		rc = readn( &c, 1, timeout );
		
        if ( rc == 1 )
        {
            *ptr++ = c;
            if ( c=='\n' )
			{
				i--;
				ptr--;
				if ( *(ptr-1) == '\r' )
				{ i--;ptr--; }
				break;
			}
        }
        else if ( rc == 0 )
        {
			*ptr = 0;
			return -1;
        }
        else
        {
            return -2;
        }
    }
    *ptr = 0;
    return i;
}

int
KConnection::readData( void *dataRead, int nchar, int &bytesRead, int timeout )
{
	if ( !_live )
	{
		return -1;
	}
    int nleft;
    int nread;
    char *ptr = (char*)dataRead;
    nleft = nchar;
	bytesRead = 0;
    while ( nleft > 0 )
    {
        if ( ( nread = readn( ptr, nleft, timeout ) ) <= 0 )
		{
			return nread;
		}
        nleft -= nread;
        ptr += nread;
        bytesRead += nread;
    }
    return 1;
}

int
KConnection::readn( void *dataRead, int nchar, int timeout )
{
	int iRead;
    assert( dataRead );
	int msec = timeout < 0 ? _timeout : timeout;
	if ( !isReadReady( msec ) )
	{
		cpLog(LOG_ERR, "QQ Timeout..");
		return 0;
	}
	
	iRead = read( _connId, dataRead, nchar );
	
	if ( iRead <= 0 )
	{
		cpLog(LOG_ERR, "QQ failed read: %d", iRead);
		if (iRead == -1)
		{
			cpLog(LOG_ERR, "errno: %d, note: %s", errno, strerror(errno));
		}
		return -1;
	}
	else
	{
		return iRead;
	}
}


int
KConnection::writeData( const string& data, int timeout )
{
    char *ptr = (char*)data.c_str();
    int nleft = data.size();
    return writeData( ptr, nleft, timeout );
}

int
KConnection::writeData( const KData& data, int timeout )
{
	int len = data.length();
	return writeData( data.getData(), len, timeout );
}

int
KConnection::writeData( const void* data, int n, int timeout )
{
	if ( !_live )
	{
		return -1;
	}
	int msec = timeout<0 ? _timeout : timeout;
    int nleft;
    int nwritten;
    char *ptr = (char*)data;
    nleft = n;
    while ( nleft > 0 )
    {
		if ( !isWriteReady( msec ) )
		{
			return ptr-(char*)data;
		}
		
		if ( ( nwritten = ::write( _connId, ptr, nleft ) ) < 0 )
		{
			if ( ptr != data )
			{
				return ptr-(char*)data;
			}
			else
			{
				return -1;
			}
        }
        nleft -= nwritten;
        ptr += nwritten;
    }
	return ptr-(char*)data;
}


string
KConnection::getDescription() const
{
    string retStr;
    SA* sa = (SA*) & _connAddr;
    const u_char* p = (const u_char*)&_connAddr.sin_addr;
    switch ( sa->sa_family )
    {
    case AF_INET:
        char temp[256];
        snprintf( temp, sizeof(temp), "%d.%d.%d.%d", p[0], p[1], p[2], p[3] );
        char pStr[56];
        sprintf( pStr, ":%d", ntohs(_connAddr.sin_port) );
        retStr = temp;
        retStr += pStr;
		return ( retStr );
        break;
	default:
        return "Unknown";
        break;
    }
    return ("Unknown");
}

string
KConnection::getIp() const
{
    string retStr;
    SA* sa = (SA*)&_connAddr;
    const u_char* p = (const u_char*)&_connAddr.sin_addr;
    switch ( sa->sa_family )
    {
	case AF_INET:
        char temp[256];
        snprintf( temp, sizeof(temp), "%d.%d.%d.%d",
					p[0], p[1], p[2], p[3] );
        retStr = temp;
        return retStr;
        break;
	default:
        return "Unknown";
        break;
    }
    return "Unknown";
}

unsigned short
KConnection::getPort() const
{
	return ntohs( _connAddr.sin_port );
}

KConnection::~KConnection()
{
	close();
}

void
KConnection::close()
{
	closeMutex.lock();
	if ( !_live )
	{
		closeMutex.unlock();
		return;
	}
	else
	{
		_live = false;
	}
	(*useNum)--;
	if ( *useNum == 0 )
	{
		assert( _connId >= 0 );
		::close( _connId );
		delete useNum;
	}
	_connId = 0;
	useNum = NULL;
	closeMutex.unlock();
}

void
KConnection::setState()
{
	closeMutex.lock();
	useNum = new int;
	*useNum = 1;
    _live = true;
	setBlocking( _blocking );
	closeMutex.unlock();
}


void
KConnection::setBlocking( bool block )
{
	_blocking = block;

	int non_blocking = _blocking ? 0 : 1;
	if ( ioctl( _connId, FIONBIO, &non_blocking ) < 0 )
	{
		//
	}
}


void 
KConnection::setTimeout( int timeout )
{
	_timeout = timeout;
}


bool
KConnection::isReadReady( int mSeconds ) const
{
    fd_set rfds;
	fd_set efds;
    struct timeval tv;
	struct timeval *ptv;
    int retval;
	FD_ZERO( &rfds );
	FD_ZERO( &efds );
	FD_SET( _connId, &rfds );
	FD_SET( _connId, &efds );
	if ( mSeconds < 0 )
	{
		ptv = NULL;
	}
	else
	{
		ptv = &tv;
		tv.tv_sec = mSeconds/1000;
		tv.tv_usec = ( mSeconds%1000 ) * 1000;
	}
    retval = select( _connId+1, &rfds, NULL, &efds, ptv );
    if ( retval>0 && FD_ISSET(_connId,&rfds) )
    {
        return true;
    }
    return false;
}

bool
KConnection::isWriteReady( int mSeconds ) const
{
    fd_set wfds;
	fd_set efds;
    struct timeval tv;
	struct timeval *ptv;
    int retval;
    FD_ZERO( &wfds );
	FD_ZERO( &efds );
    FD_SET( _connId, &wfds );
	FD_SET( _connId, &efds );
	if ( mSeconds < 0 )
	{
		ptv = NULL;
	}
	else
	{
		ptv = &tv;
		tv.tv_sec = mSeconds/1000;
		tv.tv_usec = (mSeconds%1000)*1000;
	}
    retval = select( _connId+1, NULL, &wfds, &efds, ptv );
    if ( retval>0 && FD_ISSET(_connId,&wfds) )
        return true;
    return false;
}
