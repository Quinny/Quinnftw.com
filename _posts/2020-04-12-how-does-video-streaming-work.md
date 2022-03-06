---
title: How does video streaming work?
author: QuinnP
layout: post
permalink: /how-does-video-streaming-work/
category: misc
---

A recent exploration into removing ads from streaming websites required me to
learn how video streaming really works. The results were interesting enough that
I figured I would document my journey.

# The Procotol

Many video streaming sites use a protocol called [HTTP Live Streaming (or HLS)](https://en.wikipedia.org/wiki/HTTP_Live_Streaming) to perform streaming.
The protocol is built on top of HTTP, so it is fairly easy to adopt/support.

<br />

---
![thing](https://docs-assets.developer.apple.com/published/88e87744a3/de18e941-81de-482f-843d-834a4dd3aa71.png)
*Overview of the HLS protocol [source](https://developer.apple.com/documentation/http_live_streaming/understanding_the_http_live_streaming_architecture)*

---
<br />

The basic idea behind HLS is to partition large video files into small chunks,
and then provide a manifest file that dictates the sequence and location of each
of the chunks. The chunking process allows consumers to begin playing the video
without having to download the entire file, or before the entire file even exists
yet (e.g. live streaming).

## Manifest

The manifest file used by the HLS protocol is an [M3U](https://en.wikipedia.org/wiki/M3U) file. The M3U file format was originally intended to be used to create
playlists of audio files, but has since been re-purposed for use with video files
aswell. An M3U file for a streaming video may look something like:

```
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-ALLOW-CACHE:YES
#EXT-X-TARGETDURATION:6
#EXTINF:5.00,
https://chunk-host.com/videoX/chunk1.ts
#EXTINF:6.00,
https://chunk-host.com/videoX/chunk2.ts
#EXTINF:5.00,
https://chunk-host.com/videoX/chunk3.ts
#EXTINF:4.00,
https://chunk-host.com/videoX/chunk4.ts
#EXT-X-ENDLIST
```

A few things to note:
*  `EXT-X-ENDLIST` may not be present in live streaming scenarios. This indicates
to the client that the stream is still going and the manifest should be periodically
polled for updates
*  `EXTINF` specifies the length in seconds of the file chunk. This gives the
client an idea of when it should request the next chunk.

## File Chunks

Each entry in the list represents a small slice of the overall video encoded as an [MPEG2-TS](https://en.wikipedia.org/wiki/MPEG_transport_stream) file. The entries
can either be remote URLs or local file paths (the latter is more common for
music playlists in desktop media players like iTunes).

# Video Clients

The video client implementation is easy to imagine:

*  Fetch the manifest file
*  Start downloading file chunks
*  Once a sufficient number of chunks have been fetched, start playing video
*  Continue downloading and queueing chunks in the background while playing the
already downloaded chunks in the foreground

```js
/**
 * @param {string}
 * @return {!Promise<Video>}
 */
function fetchChunk(url) {
  ...
}

/**
 * @param {string}
 * @return {!Promise<!Array<string>>}
 */
function fetchChunkLocations(manifestUrl) {
  ...
}

const chunkLocations = await fetchChunkLocations('https://chunk-host.com/manifest.m3u8');
const chunkFutures = chunkLocations.map(fetchChunk);

for (const chunkFuture of chunkFutures) {
  const chunk = await chunkFuture;
  chunk.play();
}
```

# The Phenomenon of Buffering

Shedding light on how streaming works gave me a bit of an ah-ha moment on what
exactly it means when videos "buffer". Buffering occurs when the download speed
of the chunks can't keep up with the video playback speed. In this case, the
`await chunkFuture` line of the above pseudo code will block, and thus cause pausing
and jittering in the video playback.
