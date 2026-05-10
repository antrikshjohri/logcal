import { APP_STORE_URL } from "../lib/site";

type StoreLinkProps = {
  className?: string;
  label?: string;
};

export function StoreLink({
  className = "store-badge",
  label = "Download the app"
}: StoreLinkProps) {
  return (
    <a className={className} href={APP_STORE_URL} aria-label={label}>
      <span className="store-badge-overline">App Store</span>
      <span className="store-badge-label">{label}</span>
    </a>
  );
}
