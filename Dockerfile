# syntax=docker/dockerfile:1

FROM ubuntu:22.04

ARG WHISPER_CPP_REF=v1.8.4
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        ffmpeg \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/whisper.cpp

RUN git clone --depth 1 --branch "${WHISPER_CPP_REF}" https://github.com/ggml-org/whisper.cpp.git . \
    && cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build -j"$(nproc)"

ENV PATH="/opt/whisper.cpp/build/bin:${PATH}"
ENV WHISPER_MODEL=medium

WORKDIR /workspace

COPY app/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN groupadd -r transcript --gid 1000 \
    && useradd -r -g transcript -u 1000 -d /workspace -s /bin/bash transcript \
    && chown -R transcript:transcript /workspace /opt/whisper.cpp

USER transcript

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
