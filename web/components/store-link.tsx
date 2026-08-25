import { APP_STORE_URL, GOOGLE_PLAY_URL } from "../lib/site";

type StoreLinkProps = {
  className?: string;
  onClick?: () => void;
};

export function AppStoreBadge({
  className = "store-badge",
  onClick
}: StoreLinkProps) {
  return (
    <a
      className={`${className} store-badge-apple`}
      href={APP_STORE_URL}
      aria-label="Download LogCal AI on the App Store"
      target="_blank"
      rel="noreferrer"
      onClick={onClick}
    >
      <img
        src="/badges/app-store-badge.svg"
        alt="Download on the App Store"
        width={140}
        height={42}
      />
    </a>
  );
}

export function GooglePlayBadge({
  className = "store-badge",
  onClick
}: StoreLinkProps) {
  return (
    <a
      className={`${className} store-badge-google`}
      href={GOOGLE_PLAY_URL}
      aria-label="Get LogCal AI on Google Play"
      target="_blank"
      rel="noreferrer"
      onClick={onClick}
    >
      <img
        src="/badges/google-play-badge.webp"
        alt="Get it on Google Play"
        width={426}
        height={126}
      />
    </a>
  );
}

export function StoreBadgeGroup({
  className = "store-row",
  onClick
}: StoreLinkProps) {
  return (
    <div className={className}>
      <AppStoreBadge onClick={onClick} />
      <GooglePlayBadge onClick={onClick} />
    </div>
  );
}
