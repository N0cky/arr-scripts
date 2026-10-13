#!/usr/bin/with-contenv bash
scriptVersion="1.5.8"
SMA_PATH="/usr/local/sma"
# N0cky fork: every file comes from this fixed tag instead of a moving branch, so a restart or container
# update never pulls unreviewed changes. Bump it together with a new tag (see FORK.md).
export repoRaw="https://raw.githubusercontent.com/N0cky/arr-scripts/v1.0.1"

# N0cky fork: only the package installation is skipped when it is already done; the services below are
# downloaded on every start, so the container always runs exactly the pinned version.
packagesDone=""
if [ -f /config/setup_version.txt ]; then
  source /config/setup_version.txt
  if [ "$scriptVersion" == "$setupversion" ]; then
    if apk --no-cache list | grep installed | grep opus-tools | read; then
      echo "Packages were previously installed, skipping package setup..."
      packagesDone="true"
    fi
  fi
fi
echo "setupversion=$scriptVersion" > /config/setup_version.txt

set -euo pipefail

if [ -z "$packagesDone" ]; then
echo "*** install packages ***" && \
apk add -U --upgrade --no-cache \
  tidyhtml \
  musl-locales \
  musl-locales-lang \
  flac \
  jq \
  xq \
  git \
  gcc \
  ffmpeg \
  imagemagick \
  opus-tools \
  opustags \
  python3-dev \
  libc-dev \
  uv \
  parallel \
  npm && \
echo "*** install freyr client ***" && \
apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing atomicparsley && \
npm install -g miraclx/freyr-js &&\
echo "*** install python packages ***" && \
uv pip install --system --upgrade --no-cache-dir --break-system-packages \
  jellyfish \
  beautifulsoup4 \
  yt-dlp \
  "beets<2.6" \
  yq \
  pyxDamerauLevenshtein \
  pyacoustid \
  requests \
  colorama \
  python-telegram-bot \
  pylast \
  mutagen \
  r128gain \
  deemix \
  langdetect \
  apprise \
  tidal-dl-ng-for-dj && \
echo "************ setup SMA ************"
if [ -d "${SMA_PATH}"  ]; then
  rm -rf "${SMA_PATH}"
fi
echo "************ download repo ************" && \
git clone --depth 1 https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
echo "************ create logging file ************" && \
touch ${SMA_PATH}/config/sma.log && \
chgrp users ${SMA_PATH}/config/sma.log && \
chmod g+w ${SMA_PATH}/config/sma.log && \
echo "************ install pip dependencies ************" && \
uv pip install --system --break-system-packages -r ${SMA_PATH}/setup/requirements.txt
fi

mkdir -p /custom-services.d/python /config/extended

parallel ::: \
  'echo "Download QueueCleaner service..." && curl -sfL ${repoRaw}/universal/services/QueueCleaner -o /custom-services.d/QueueCleaner && echo "Done"' \
  'echo "Download AutoConfig service..." && curl -sfL ${repoRaw}/lidarr/AutoConfig.service.bash -o /custom-services.d/AutoConfig && echo "Done"' \
  'echo "Download Video service..." && curl -sfL ${repoRaw}/lidarr/Video.service.bash -o /custom-services.d/Video && echo "Done"' \
  'echo "Download Tidal Video Downloader service..." && curl -sfL ${repoRaw}/lidarr/TidalVideoDownloader.bash -o /custom-services.d/TidalVideoDownloader && echo "Done"' \
  'echo "Download Audio service..." && curl -sfL ${repoRaw}/lidarr/Audio.service.bash -o /custom-services.d/Audio && echo "Done"' \
  'echo "Download AutoArtistAdder service..." && curl -sfL ${repoRaw}/lidarr/AutoArtistAdder.bash -o /custom-services.d/AutoArtistAdder && echo "Done"' \
  'echo "Download UnmappedFilesCleaner service..." && curl -sfL ${repoRaw}/lidarr/UnmappedFilesCleaner.bash -o /custom-services.d/UnmappedFilesCleaner && echo "Done"' \
  'echo "Download ARLChecker service..." && curl -sfL ${repoRaw}/lidarr/python/ARLChecker.py -o /custom-services.d/python/ARLChecker.py && curl -sfL ${repoRaw}/lidarr/ARLChecker -o /custom-services.d/ARLChecker && echo "Done"' \
  'echo "Download Script Functions..." && curl -sfL ${repoRaw}/universal/functions.bash -o /config/extended/functions && echo "Done"' \
  'echo "Download PlexNotify script..." && curl -sfL ${repoRaw}/lidarr/PlexNotify.bash -o /config/extended/PlexNotify.bash  && echo "Done"' \
  'echo "Download SMA config..." && curl -sfL ${repoRaw}/lidarr/sma.ini -o /config/extended/sma.ini  && echo "Done"' \
  'echo "Download LyricExtractor script..." && curl -sfL ${repoRaw}/lidarr/LyricExtractor.bash -o /config/extended/LyricExtractor.bash && echo "Done"' \
  'echo "Download ArtworkExtractor script..." && curl -sfL ${repoRaw}/lidarr/ArtworkExtractor.bash -o /config/extended/ArtworkExtractor.bash && echo "Done"' \
  'echo "Download Beets Tagger script..." && curl -sfL ${repoRaw}/lidarr/BeetsTagger.bash -o /config/extended/BeetsTagger.bash && echo "Done"'


if [ ! -f /config/extended/beets-config.yaml ]; then
	echo "Download Beets config..."
	curl -sfL "${repoRaw}/lidarr/beets-config.yaml" -o /config/extended/beets-config.yaml
	echo "Done"
fi

if [ ! -f /config/extended/beets-config-lidarr.yaml ]; then
	echo "Download Beets lidarr config..."
	curl -sfL "${repoRaw}/lidarr/beets-config-lidarr.yaml" -o /config/extended/beets-config-lidarr.yaml
	echo "Done"
fi

if [ ! -f /config/extended/deemix_config.json ]; then
  echo "Download Deemix config..."
  curl -sfL "${repoRaw}/lidarr/deemix_config.json" -o /config/extended/deemix_config.json
  echo "Done"
fi

if [ ! -f /config/extended/tidal-dl.json ]; then
  echo "Download Tidal (tidal-dl-ng) config..."
  curl -sfL "${repoRaw}/lidarr/tidal-dl.json" -o /config/extended/tidal-dl.json
  echo "Done"
fi

if [ ! -f /config/extended/beets-genre-whitelist.txt ]; then
	echo "Download beets-genre-whitelist.txt..."
	curl -sfL ${repoRaw}/lidarr/beets-genre-whitelist.txt -o /config/extended/beets-genre-whitelist.txt
	echo "Done"
fi

if [ ! -f /config/extended.conf ]; then
	echo "Download Extended config..."
	curl -sfL ${repoRaw}/lidarr/extended.conf -o /config/extended.conf
	chmod 777 /config/extended.conf
	echo "Done"
fi

chmod 777 -R /config/extended
chmod 777 -R /root

# N0cky fork: LSIO copies custom-services.d to /run/service/custom-svc-<Name>/run *before* custom-cont-init
# runs, so the services downloaded above would only run after the next start. Refresh those copies now
# (new inode via mv; a service that is already up gets restarted), so a new tag is active after one restart.
for svc in /custom-services.d/*; do
  [ -f "$svc" ] || continue
  dir="/run/service/custom-svc-$(basename "$svc")"
  [ -f "$dir/run" ] || continue
  cmp -s "$svc" "$dir/run" && continue
  cp "$svc" "$dir/run.new" && chmod 755 "$dir/run.new" && mv "$dir/run.new" "$dir/run"
  echo "Activated new $(basename "$svc") service"
  if /command/s6-svstat -u "$dir" 2>/dev/null | grep -q true; then
    /command/s6-svc -r "$dir" && echo "Restarted running $(basename "$svc") service"
  fi
done

if [ -f /custom-services.d/scripts_init.bash ]; then
   # user misconfiguration detected, sleeping...
   sleep infinity
fi
exit