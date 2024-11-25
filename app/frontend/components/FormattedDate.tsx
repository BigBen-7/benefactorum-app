export default function FormattedDate({ isoDate }) {
  const parsedDate = new Date(isoDate);
  const formattedDate = parsedDate.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  });
  return formattedDate;
}