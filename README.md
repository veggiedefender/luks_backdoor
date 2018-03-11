# luks_backdoor
Places a backdoor on a LUKS encrypted partition via an unprotected initramfs

## Background
It's common practice to use LUKS to encrypt all partitions on a machine except for `/boot`, which the ESP must access in order
to decrypt the rest of the partitions. This PoC shows that it is easy to modify the initramfs, stored on `/boot` to add a LUKS
key at the same time as it decrypts the partitions.

## Threat model
This attack requires physical access, and for the target to log in to decrypt the partitions at least once between planting the
backdoor and using it. Examples:

* evil roommate
* evil administrator
* you?

## How it works
This script does the following:

* mount the user-supplied ESP
* back up the initramfs (assumed to be called `initramfs-linux.img`)
* extract the initramfs using `lsinitcpio`
* modify the `encrypt` hook*
* repack the initramfs

\* By default, the `encrypt` hook asks the user to decrypt the disk by simply running

```
cryptsetup open --type luks ${resolved} ${cryptname} ${cryptargs} ${CSQUIET}
```

Our modified `encrypt` hook now prompts the user for the password, storing it in a variable. Then, it checks if the password
is valid by running the same `cryptsetup open` that it normally uses, and if that succeeds, it adds a new key (default: `rekt`).

## Limitations
* Niche use-case (see [Threat model](#threat-model))
* Noticeably longer time (approx. 2x) to decrypt, since adding the key takes a long time, in addition to the time it already takes
decrypting the drive
* Easy to mitigate. See [Mitigations](#mitigations)

## Mitigations
Fortunately, this attack is easy to defend against with normal security practices. A non-exhaustive list in no particular order:
* Store `/boot` on a separate drive kept on your person
* Encrypt `/boot` (Only GRUB can do this, as far as I'm aware)
* Fill up all eight LUKS key slots (prevents adding new ones)
* Watch for the extra time it takes to decrypt the drive
* Keep track of the number of keys returned by `cryptsetup luksDump <partition>`
