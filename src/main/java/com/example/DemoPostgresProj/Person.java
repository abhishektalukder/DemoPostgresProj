package com.example.DemoPostgresProj;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "person_table_1")
public class Person {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
}
