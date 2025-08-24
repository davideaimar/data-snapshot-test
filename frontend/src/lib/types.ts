export interface Summary {
  generated_at: string;
  summary: {
    total_volumes: number;
    total_commits: number;
    volume_stats: VolumeStat[];
  };
}

export interface VolumeStat {
  name: string;
  commits: number;
  latest_date: string;
  total_files: number;
  total_size: number;
}

export interface Volumes {
  generated_at: string;
  volumes: Record<string, { commits: Commit[] }>;
}

export interface Commit {
  hash: string;
  date: string;
  message: string;
  stats: {
    file_count: number;
    total_size: number;
  };
}

export interface CommitDetails extends Commit {
  volume: string;
  files: Record<string, { size: number; sha256: string }>;
}
