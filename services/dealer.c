#include <zmq.h>
#include <assert.h>

int main ( int argc, char *argv[] )
{
  void *context = zmq_init (1);
  assert(context);

  //  Create frontend and backend sockets
  void *frontend = zmq_socket (context, ZMQ_XREP);
  assert (frontend);
  void *backend = zmq_socket (context, ZMQ_XREQ);
  assert (backend);
  //  Bind both sockets to TCP ports
  assert (zmq_bind (frontend, argv[1]) == 0);
  assert (zmq_bind (backend, argv[2]) == 0);
  /* assert (zmq_bind (frontend, "tcp://\*:4446") == 0); */
  /* assert (zmq_bind (backend, "tcp://\*:13000") == 0); */
  zmq_device (ZMQ_QUEUE, frontend, backend);
}
