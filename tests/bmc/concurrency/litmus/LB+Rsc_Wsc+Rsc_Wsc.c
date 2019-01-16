
#include <stdatomic.h>
int main() {
  _Atomic(int) x=0, y=0;
  int z1, z2;

  {-{ { z1 = atomic_load_explicit(&x, memory_order_seq_cst); 
        atomic_store_explicit(&y, 1, memory_order_seq_cst); }
  ||| { z2 = atomic_load_explicit(&y, memory_order_seq_cst);
        atomic_store_explicit(&x, 1, memory_order_seq_cst); }  }-};
  return z1 + (2 * z2);
}

