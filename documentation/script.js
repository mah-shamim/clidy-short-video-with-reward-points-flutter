// script.js

document.addEventListener('DOMContentLoaded', () => {
  // Accordion in the sidebar menu (remains the same)
  const accordionItems = document.querySelectorAll('.accordion-item');
  accordionItems.forEach(item => {
    const link = item.querySelector('a');
    link.addEventListener('click', event => {
      event.preventDefault();
      const submenu = item.querySelector('.submenu');
      if (item.classList.contains('open')) {
        submenu.style.display = 'none';
        item.classList.remove('open');
      } else {
        document.querySelectorAll('.submenu').forEach(sub => sub.style.display = 'none');
        document.querySelectorAll('.accordion-item').forEach(acc => acc.classList.remove('open'));
        submenu.style.display = 'block';
        item.classList.add('open');
      }
    });
  });

  // Smooth scrolling for the links
  document.querySelectorAll('aside a').forEach(link => {
    link.addEventListener('click', event => {
      event.preventDefault();
      const targetId = link.getAttribute('href').substring(1);
      const targetSection = document.getElementById(targetId);
      targetSection.scrollIntoView({
        behavior: 'smooth',
        block: 'start'
      });
    });
  });

  // Image zoom functionality
  const images = document.querySelectorAll('.documentation-item img');
  const modal = document.createElement('div');
  modal.classList.add('image-modal');
  modal.innerHTML = `
    <span class="close-btn">&times;</span>
    <img src="" alt="Full-size image">
  `;
  document.body.appendChild(modal);

  const modalImg = modal.querySelector('img');
  const closeModalBtn = modal.querySelector('.close-btn');

  images.forEach(image => {
    image.addEventListener('click', () => {
      modal.style.display = 'flex';
      modalImg.src = image.src;
    });
  });

  // Close the modal when the close button is clicked
  closeModalBtn.addEventListener('click', () => {
    modal.style.display = 'none';
  });

  // Close the modal when clicking outside the image
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      modal.style.display = 'none';
    }
  });
});
