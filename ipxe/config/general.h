// image types
//#ifndef CONSOLE_EFI
//#define IMAGE_NBI               /* NBI image support */
//#define IMAGE_ELF               /* ELF image support */
//#define IMAGE_MULTIBOOT         /* MultiBoot image support */
//#define IMAGE_PXE               /* PXE image support */
//#endif
//#define IMAGE_SCRIPT            /* iPXE script image support */
//#ifndef CONSOLE_EFI
//#define IMAGE_BZIMAGE           /* Linux bzImage image support */
//#define IMAGE_COMBOOT           /* SYSLINUX COMBOOT image support */
//#endif
//#define IMAGE_EFI               /* EFI image support */
//#define IMAGE_SDI               /* SDI image support */

// protocols
#define NET_PROTO_IPV4          /* IPv4 protocol */
#define NET_PROTO_IPV6          /* IPv6 protocol */
#define DOWNLOAD_PROTO_HTTPS    /* Secure Hypertext Transfer Protocol */
#define DOWNLOAD_PROTO_FTP      /* File Transfer Protocol */
//#define DOWNLOAD_PROTO_SLAM     /* Scalable Local Area Multicast */

// commands
#define NSLOOKUP_CMD          /* DNS resolving command */
#define TIME_CMD              /* Time commands */
//#define DIGEST_CMD            /* Image crypto digest commands */
#define LOTEST_CMD            /* Loopback testing commands */
#define VLAN_CMD              /* VLAN commands */
// incompatible with efi build
//#ifndef CONSOLE_EFI
//#define PXE_CMD               /* PXE commands */
//#endif
#define REBOOT_CMD            /* Reboot command */
#define POWEROFF_CMD          /* Power off command */
#define IMAGE_TRUST_CMD       /* Image trust management commands */
#define PCI_CMD             /* PCI commands */
#define PARAM_CMD             /* Form parameter commands */
#define NEIGHBOUR_CMD         /* Neighbour management commands */
#define PING_CMD              /* Ping command */
#define CONSOLE_CMD           /* Console command */
#define IPSTAT_CMD            /* IP statistics commands */
#define PROFSTAT_CMD          /* Profiling commands */
#define NTP_CMD               /* NTP commands */
#define CERT_CMD              /* Certificate management commands */
//#define IMAGE_MEM_CMD         /* Read memory command */
#define IMAGE_ARCHIVE_CMD     /* Archive image management commands */

// error messages
#define  ERRMSG_80211		/* All 802.11 error descriptions (~3.3kb) */

// The Tivoli VMM workaround causes KVM and some other hosts to crash.
#undef TIVOLI_VMM_WORKAROUND
