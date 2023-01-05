---
date: 2023-01-04T22:51
title: Fixing manually deleted Docker volume
---

Let's say you have a docker-compose file that looks like this:

```yaml
version: '3.1'

services:

  db:
    image: postgres
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: my_db
    volumes:
      - db-data:/var/lib/postgresql/data
    ports:
      - 5432:5432


volumes:
  db-data:
```

If you're not thinking straight or are not very experienced with docker, you may 
delete your volume in order to clean it using something similar to the following command:

```bash
sudo rm -rf /var/lib/docker/volumes/db-data
```

And then you proceed to run your containers normally with docker comopse,
and boom!

```bash
❯ docker compose up
[+] Running 1/0
 ⠿ Network default  Created                                                                                 0.0s
 ⠋ Container db-1   Creating                                                                                0.0s
Error response from daemon: open /var/lib/docker/volumes/db-data/_data: no such file or directory
```

Now we can't run our containers, what should we do!?

Doing a quick google search, we see that docker compose has the following flag:
```
-V, --renew-anon-volumes   Recreate anonymous volumes instead of retrieving
                           data from the previous containers.
```

Now it seems that this battle is already won, but surprisingly, when using
**docker v20.10.21** and **docker-compose v2.14.0**, adding this flag to `docker compose
up` does nothing, the error still persists and no volume is recreated.

The way that I've solved this is actually pretty stupid, but it works
flawlessly:

```bash
sudo mkdir -p /var/lib/docker/volumes/db-data/_data
```

Creating these folders is already enough for `docker-compose` to continue from
there and run our containers.

And maybe the key takeway from this is to remember to use `docker volume rm`
when wiping volumes, so we don't run through this again.
