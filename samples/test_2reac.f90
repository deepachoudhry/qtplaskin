!
! TWO-REACTION TEST CASE
! ZDPLASKIN
!
! This test case corresponds to an Ar plasma consisting of electrons, atomic
! ions, and neutrals. The charged particles are supposed to be generated by
! direct electron impact ionization and lost by 3-body recombination.
!
! June 2008, by S Pancheshnyi
! June 2010, adapted to produce output compatible with qtplaskin, by A Luque
!

program test_2reac
!
! declare variables and modules
!
  use ZDPlasKin
  implicit none
  double precision, parameter :: gas_temperature  = 300.0d0, & ! gas temperature, K
                                 reduced_field    = 50.0d0,  & ! reduced electric field, Td
                                 density_ini_ar   = 2.5d19,  & ! initial Ar density, cm-3
                                 density_ini_elec = 1.0d0      ! initial electron density, cm-3
  double precision            :: time  = 0.0d0, time_end = 3.0d-7, dtime = 1.0d-8 ! times, s
  double precision            :: elec_temperature
  integer                     :: i

  double precision, allocatable :: reaction_rates(:), source_matrix(:, :)

!
! print
!
  write(*,'(/,A)') 'TWO-REACTION TEST CASE'
!
! initialization of ZDPlasKin
!
  call ZDPlasKin_init()
!
! set the physical conditions of the calculation:
!     the gas temperature and the reduced electric field
!
  call ZDPlasKin_set_conditions(GAS_TEMPERATURE=gas_temperature,REDUCED_FIELD=reduced_field )
!
! set initial densities
!
  call ZDPlasKin_set_density(  'Ar',density_ini_ar)
  call ZDPlasKin_set_density(   'e',density_ini_elec)
  call ZDPlasKin_set_density('Ar^+',density_ini_elec)


!-------------------------------------------------------
!
! We have to write several files to allow realtime plotting.
! A list of all the species that we will save in out_density.txt.
! The order of species names in species_list.txt has to match the order
! of columns in out_density.txt.
  open(14,file='species_list.txt')
  do i = 1, species_max
     write(14,*) trim(species_name(i))
  enddo
  close(14)

!-------------------------------------------------------
!
! A list of all reactions that we will save in out_rate.txt.
! Again, orders have to match.
!

  open(14,file='reactions_list.txt')
  do i = 1, reactions_max
     write(14,*) trim(reaction_sign(i))
  enddo
  close(14)

!-------------------------------------------------------
!
! A list of all available 'conditions': in out_condition.dat.
! The order hast to match here too.
! Note that you can use this list and out_condition to save any time-dependent
! variable that you would like to inspect using qtplaskin.
!

  open(14,file='conditions_list.txt')
     write(14,*) 'reduced_field'
     write(14,*) 'gas_temperature'
     write(14,*) 'elec_temperature'
  close(14)

!-------------------------------------------------------
!
! For the sensitivity analysis we must know how reaction i affects species j.
! We could save that information for each reaction, each species and each
! time but that would be extremely wasteful.  Instead, we save at the 
! beginning a matrix with the stechiometric coefficient of each reaction and
! species.  This is accomplished by artificially giving each reaction rate
! a value of one and calling ZDPlasKin_reac_source_matrix.
!

  allocate(reaction_rates(reactions_max), &
       source_matrix(species_max, reactions_max))
  reaction_rates(:) = 1.0d0
  call ZDPlasKin_reac_source_matrix(reaction_rates, source_matrix)
  open(14,file='source_matrix.txt')
  do i = 1, species_max
     write(14,'(999(i3))') int(source_matrix(i,:))
  enddo
  close(14)
  deallocate(source_matrix)

!-------------------------------------------------------
!
! Print file headers 
! Note that the first line is simply ignored by qtplaskin, so it serves only
! to help humans inspect the files.

  open(1,file='out_density.txt')
  write(1,'(99(A10))') 'Time', (trim(species_name(i)), i = 1, species_max)
  	
  open(2,file='out_temperatures.txt')
  write(2,'(4(A12))') 'Time', 'E/N', 'Tgas', 'Te'

  open(3,file='out_rate.txt')
  write(3,'(999(A40))') 'Time', (trim(reaction_sign(i)), i = 1, reactions_max)


!
! print column headers and initial values
!
  write(*,'(4(A12))') 'Time_s', ( trim(species_name(i)), i = 1, species_max )
  write(*,'(4(1pe12.4))') time, density(:)
!
! time integration
!
  do while(time .lt. time_end)
    call ZDPlasKin_timestep(time,dtime)
    time = time + dtime
    write(*,'(4(1pe12.4))') time, density(:)

    ! truncate very small densities.  This saves space and avoids I/O
    ! problems with exponents smaller that -99
    where (density < 1.0d-40) density = 0.0d0
    
    write(1,'(99(1pe12.4))') time, density(:)
    call ZDPlaskin_get_conditions(elec_temperature=elec_temperature)
    write(2,'(4(1pe12.4))') time, reduced_field, gas_temperature, elec_temperature
    call ZDPlasKin_get_rates(reaction_rates=reaction_rates)
    write(3,'(999(1pe12.4))') time, reaction_rates(:)
    
    ! These flushes here are needed to keep all files in sync, allowing
    ! runtime readings by qtplaskin
    flush(1)
    flush(2)
    flush(3)

  enddo
!
! end
!
  write(*,'(/,A,$)') 'PRESS ENTER TO EXIT ...'
  read(*,*)
end program test_2reac