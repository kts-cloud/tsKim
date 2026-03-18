#ifndef SYS_ARCH_H
#define SYS_ARCH_H

/* NO_SYS=1: no threading primitives needed.
 * lwIP still requires these type/macro stubs to compile. */

typedef int sys_prot_t;

#define SYS_ARCH_DECL_PROTECT(lev)   (void)(lev)
#define SYS_ARCH_PROTECT(lev)        (void)(lev)
#define SYS_ARCH_UNPROTECT(lev)      (void)(lev)

#endif /* SYS_ARCH_H */
