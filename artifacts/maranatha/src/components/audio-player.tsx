import { useRef, useState, useEffect } from "react";
import { Play, Pause, SkipBack, Volume2, Radio } from "lucide-react";
import { Slider } from "@/components/ui/slider";

interface AudioPlayerProps {
  url: string | null | undefined;
  title: string;
  coverArt: string | null | undefined;
}

export function AudioPlayer({ url, title, coverArt }: AudioPlayerProps) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [autoplayBlocked, setAutoplayBlocked] = useState(false);
  const prevUrlRef = useRef<string | null | undefined>(null);

  useEffect(() => {
    if (!audioRef.current || url === prevUrlRef.current) return;
    prevUrlRef.current = url;

    if (!url) {
      setIsPlaying(false);
      setProgress(0);
      setAutoplayBlocked(false);
      return;
    }

    audioRef.current.load();
    setProgress(0);
    setAutoplayBlocked(false);

    const attemptPlay = () => {
      if (!audioRef.current) return;
      audioRef.current
        .play()
        .then(() => {
          setIsPlaying(true);
          setAutoplayBlocked(false);
        })
        .catch(() => {
          setIsPlaying(false);
          setAutoplayBlocked(true);
        });
    };

    if (audioRef.current.readyState >= 2) {
      attemptPlay();
    } else {
      audioRef.current.addEventListener("canplay", attemptPlay, { once: true });
    }
  }, [url]);

  const togglePlay = () => {
    if (!audioRef.current || !url) return;
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().catch(console.error);
      setIsPlaying(true);
      setAutoplayBlocked(false);
    }
  };

  const handleTimeUpdate = () => {
    if (audioRef.current) {
      setProgress(audioRef.current.currentTime);
    }
  };

  const handleLoadedMetadata = () => {
    if (audioRef.current) {
      setDuration(audioRef.current.duration);
    }
  };

  const skip = (amount: number) => {
    if (audioRef.current) {
      audioRef.current.currentTime += amount;
    }
  };

  const handleSliderChange = (value: number[]) => {
    if (audioRef.current) {
      audioRef.current.currentTime = value[0];
      setProgress(value[0]);
    }
  };

  const formatTime = (time: number) => {
    if (!time || isNaN(time)) return "00:00";
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  };

  return (
    <div className="bg-zinc-900 text-white rounded-2xl p-6 shadow-2xl relative overflow-hidden border border-zinc-800">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-red-600 to-red-900"></div>

      {url && (
        <audio
          ref={audioRef}
          src={url}
          onTimeUpdate={handleTimeUpdate}
          onLoadedMetadata={handleLoadedMetadata}
          onEnded={() => setIsPlaying(false)}
          onPlay={() => setIsPlaying(true)}
          onPause={() => setIsPlaying(false)}
        />
      )}

      <div className="flex flex-col items-center">
        <div className="w-48 h-48 rounded-xl overflow-hidden mb-6 shadow-lg shadow-black/50 border border-zinc-700 bg-zinc-800 flex items-center justify-center relative">
          {coverArt ? (
            <img src={coverArt} alt="Pochette" className="w-full h-full object-cover" />
          ) : (
            <Volume2 className="w-16 h-16 text-zinc-600" />
          )}
          {isPlaying && (
            <div className="absolute bottom-2 left-1/2 -translate-x-1/2 flex items-end gap-0.5">
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="w-1 bg-red-500 rounded-full"
                  style={{
                    height: `${8 + i * 4}px`,
                    animation: `equalizer ${0.4 + i * 0.1}s ease-in-out infinite alternate`,
                  }}
                />
              ))}
            </div>
          )}
        </div>

        <h3 className="font-sans font-bold text-xl text-center mb-1 line-clamp-1">
          {title || "Aucune diffusion en cours"}
        </h3>
        <p className="text-zinc-400 text-sm mb-2 uppercase tracking-wider">Maranatha Ministère</p>

        {autoplayBlocked && url && (
          <button
            onClick={togglePlay}
            className="mb-4 flex items-center gap-2 bg-red-600/20 border border-red-600/40 text-red-400 text-xs px-4 py-2 rounded-full animate-pulse hover:bg-red-600/30 transition-colors"
            data-testid="autoplay-blocked-hint"
          >
            <Radio className="w-3 h-3" />
            Appuyer pour écouter en direct
          </button>
        )}

        {!autoplayBlocked && <div className="mb-4" />}

        <div className="w-full space-y-2 mb-6">
          <Slider
            value={[progress]}
            max={duration || 100}
            step={1}
            onValueChange={handleSliderChange}
            className="[&_[role=slider]]:bg-red-600 [&_[role=slider]]:border-red-600 [&_[role=slider]]:w-4 [&_[role=slider]]:h-4 [&>.relative>.absolute]:bg-red-600"
            disabled={!url}
          />
          <div className="flex justify-between text-xs text-zinc-500 font-mono">
            <span>{formatTime(progress)}</span>
            <span>{formatTime(duration)}</span>
          </div>
        </div>

        <div className="flex items-center justify-center gap-6">
          <button
            onClick={() => skip(-10)}
            disabled={!url}
            className="text-zinc-400 hover:text-white transition-colors disabled:opacity-50"
            data-testid="audio-skip-back"
          >
            <SkipBack className="w-8 h-8" />
          </button>

          <button
            onClick={togglePlay}
            disabled={!url}
            className="w-16 h-16 rounded-full bg-gradient-to-br from-red-500 to-red-700 flex items-center justify-center text-white shadow-lg shadow-red-900/20 hover:scale-105 transition-transform disabled:opacity-50 disabled:hover:scale-100"
            data-testid="audio-play-pause"
          >
            {isPlaying ? (
              <Pause className="w-8 h-8 fill-current" />
            ) : (
              <Play className="w-8 h-8 fill-current ml-1" />
            )}
          </button>

          <button
            onClick={() => skip(10)}
            disabled={!url}
            className="text-zinc-400 hover:text-white transition-colors disabled:opacity-50"
            data-testid="audio-skip-forward"
          >
            <SkipBack className="w-8 h-8 rotate-180" />
          </button>
        </div>
      </div>

      <style>{`
        @keyframes equalizer {
          from { transform: scaleY(0.3); }
          to { transform: scaleY(1); }
        }
      `}</style>
    </div>
  );
}
