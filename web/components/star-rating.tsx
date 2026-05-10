import { Star } from "lucide-react";

type FiveStarRatingProps = {
  className?: string;
  /** Visually-hidden label for assistive tech */
  label?: string;
  iconClassName?: string;
};

/** Five filled stars — decorative; use `label` for the accessible rating text. */
export function FiveStarRating({
  className = "",
  label = "5 out of 5 stars",
  iconClassName = "star-rating-icon"
}: FiveStarRatingProps) {
  return (
    <div
      className={`star-rating-row ${className}`}
      role="img"
      aria-label={label}
    >
      {Array.from({ length: 5 }, (_, i) => (
        <Star
          key={i}
          className={iconClassName}
          size={22}
          fill="currentColor"
          stroke="currentColor"
          strokeWidth={1}
          aria-hidden
        />
      ))}
    </div>
  );
}
