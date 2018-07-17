# luks_backdoor
Places a backdoor on a LUKS encrypted partition via an unprotected initramfs

## Background
It's common practice to use LUKS to encrypt all partitions on a machine except for `/boot`, which the ESP must access in order
to decrypt the rest of the partitions. This PoC shows that it is easy to modify the initramfs, stored on `/boot` to add a LUKS
key at the same time as it decrypts the partitions.

## Threat model
This attack requires physical access, and for the target to log in to decrypt the partitions at least once between planting the
backdoor and using it. Examples:

* evil maid
* evil roommate
* evil administrator
* you?

## How it works
This script does the following:

* mount the user-supplied ESP
* back up the user-supplied initramfs (assumed to be called `initramfs-linux.img`)
* extract that initramfs using `lsinitcpio`
* modify the `encrypt` hook*
* repack the initramfs

\* By default, the `encrypt` hook asks the user to decrypt the disk by simply running

```
cryptsetup open --type luks ${resolved} ${cryptname} ${cryptargs} ${CSQUIET}
```

Our modified `encrypt` hook now prompts the user for the password, storing it in a variable. Then, it checks if the password
is valid by running the same `cryptsetup open` that it normally uses, and if that succeeds, it adds a new key (default: `rekt`).

## Usage

```
# This works with a default initramfs named initramfs-linux.img
sudo ./rekt.sh /dev/mapper/boot-partition
# This works with custom initramfs names (note the lack of the .img)
sudo ./rekt.sh /dev/mapper/boot-partition initramfs-name
```

## Limitations
* Niche use-case (see [Threat model](#threat-model))
* Noticeably longer time (approx. 2x) to decrypt, since adding the key takes a long time, in addition to the time it already takes
decrypting the drive
* Easy to mitigate. See [Mitigations](#mitigations)

## Mitigations
Fortunately, this attack is easy to defend against with normal security practices. A non-exhaustive list in no particular order:
* Store `/boot` on a separate drive kept on your person
* Encrypt `/boot` (Only GRUB can do this, as far as I'm aware)
* Set a BIOS password (Will help a little bit but likely not a lot if your attacker has physical access and time)
* Watch for the extra time it takes to decrypt the drive
