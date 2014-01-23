// image types
#define       IMAGE_NBI               /* NBI image support */
#define       IMAGE_ELF               /* ELF image support */
#define       IMAGE_MULTIBOOT         /* MultiBoot image support */
#define       IMAGE_PXE               /* PXE image support */
#define       IMAGE_SCRIPT            /* iPXE script image support */
#define       IMAGE_BZIMAGE           /* Linux bzImage image support */
#define       IMAGE_COMBOOT           /* SYSLINUX COMBOOT image support */
//#define       IMAGE_EFI               /* EFI image support */
#define       IMAGE_SDI               /* SDI image support */
#define       IMAGE_PNM               /* PNM image support */
#define       IMAGE_PNG               /* PNG image support */

// protocols
#define        DOWNLOAD_PROTO_HTTPS    /* Secure Hypertext Transfer Protocol */
#define        DOWNLOAD_PROTO_FTP      /* File Transfer Protocol */
//#define        DOWNLOAD_PROTO_SLAM     /* Scalable Local Area Multicast */

// commands
#define NSLOOKUP_CMD          /* DNS resolving command */
#define TIME_CMD              /* Time commands */
//#define DIGEST_CMD            /* Image crypto digest commands */
#define LOTEST_CMD            /* Loopback testing commands */
#define VLAN_CMD              /* VLAN commands */
#define PXE_CMD               /* PXE commands */
#define REBOOT_CMD            /* Reboot command */
#define POWEROFF_CMD          /* Power off command */
#define IMAGE_TRUST_CMD       /* Image trust management commands */
#define PCI_CMD             /* PCI commands */
#define PARAM_CMD             /* Form parameter commands */
#define NEIGHBOUR_CMD         /* Neighbour management commands */
#define PING_CMD              /* Ping command */
#define CONSOLE_CMD           /* Console command */

// error messages
#define  ERRMSG_80211		/* All 802.11 error descriptions (~3.3kb) */
